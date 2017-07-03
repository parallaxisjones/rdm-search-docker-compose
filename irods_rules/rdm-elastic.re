#-----------------------------------------------------------------------
# rdmIndexCollection: create or update collection in the Elastic 
#                     index server 
#
# collection acquires a 'tobeindex=1' attribute when the operation failed. 
#
# [Input]
#  - *collId: the irods collection id 
#  - *elasticIndexURL: the Elastic index endpoint URL
#-----------------------------------------------------------------------
rdmIndexCollection( *collId, *elasticIndexURL ) {

    *collName = '';
    *ec = errormsg(rdmGetCollectionAttributesJSON(*collId, *collName, false, false, *jsonStr, *isClosedDSC), *errmsg);
    
    if ( *ec == 0 ) {
        *postFields."data" = *jsonStr;
        *docURL = *elasticIndexURL ++ '/collection/' ++ *collId;
        *ec = errormsg( msiCurlPut(*docURL, *postFields, *response), *errmsg);

        *rsp.'result' = '';
        msi_json_objops( *response, *rsp, "get" );

        if ( str(*rsp.'result') != 'created' && str(*rsp.'result') != 'updated' ) {
            # set *ec to non-zero when the result is not about create or update
            *ec = 1;
        }
    }

    *kvp.'tobeindexed' = '1';
    if ( *ec != 0 ) {
        *ec = errormsg(rdmUpdateCollectionAttributes(*collName, 'add', list(*kvp)), *errmsg);
        rdmLog(LOG_ERR, '', '[RDM COLL TOBEINDEXED] ' ++ *collId );
    } else {
        *ec = errormsg(rdmUpdateCollectionAttributes(*collName, 'rm', list(*kvp)), *errmsg);
    }
}

#-----------------------------------------------------------------------
# rdmIndexUser: create or update user in the Elastic index server 
#
# user acquires a 'tobeindex=1' attribute when the operation failed. 
#
# [Input]
#  - *userName: the irods user name 
#  - *elasticIndexURL: the Elastic index endpoint URL
#-----------------------------------------------------------------------
rdmIndexUser( *userName, *elasticIndexURL ) {

    *collName = '';
    *ec = errormsg(rdmGetUserProfileJSON(*userName, 'null', true, *jsonStr), *errmsg);
    
    if ( *ec == 0 ) {
        *postFields."data" = *jsonStr;
        *docURL = *elasticIndexURL ++ '/user/' ++ *userName;
        *ec = errormsg( msiCurlPut(*docURL, *postFields, *response), *errmsg);

        *rsp.'result' = '';
        msi_json_objops( *response, *rsp, "get" );

        if ( str(*rsp.'result') != 'created' && str(*rsp.'result') != 'updated' ) {
            # set *ec to non-zero when the result is not about create or update
            *ec = 1;
        }
    }

    *kvp.'tobeindexed' = '1';
    if ( *ec != 0 ) {
        *ec = errormsg(rdmSudoUpdateUserAttributes(*userName, 'add', list(*kvp)), *errmsg);
        rdmLog(LOG_ERR, '', '[RDM USER TOBEINDEXED] ' ++ *userName );
    } else {
        *ec = errormsg(rdmSudoUpdateUserAttributes(*userName, 'rm', list(*kvp)), *errmsg);
    }
}

#-----------------------------------------------------------------------
# rdmIndexAllCollections: (re)index collections in the system or fail the
#                         previous indexing operation (i.e. with 
#                         'tobeindexed' attributed)
#
# [Input]
#  - *elasticIndexURL: the 'rdm' elastic index URL 
#  - *full: set 'true' for reindexing all collections; otherwiser only
#           the collections with attribute 'tobeindexed' 
#-----------------------------------------------------------------------
rdmIndexAllCollections(*elasticIndexURL, *full) {

    *qry_attr = "COLL_ID";
    *qry_cond = "META_COLL_ATTR_NAME = 'tobeindexed' AND META_COLL_ATTR_VALUE = '1'";

    if ( bool(*full) ) {
        # all RDM collections have parent namespace: /ZONE_NAME/O/OU
        *qry_cond = "COLL_PARENT_NAME in (";
        foreach( *o in O_LIST ) {
            foreach( *ou in OU_LIST ) {
                *qry_cond = *qry_cond ++ "'/" ++ ZONE_NAME ++ '/' ++ *o ++ '/' ++ *ou ++ "',";
            }
        }
        *qry_cond = trimr(*qry_cond, ',') ++ ")";
    }
 
    msiMakeGenQuery(*qry_attr, *qry_cond, *genQryInp);
    msiExecGenQuery(*genQryInp, *qry_out);
    msiGetContInxFromGenQueryOut(*qry_out, *cntIdx); 
 
    *cntIdxOld = 1;

    *collIds = list(); 
    while( *cntIdxOld > 0 ) { 
        foreach(*r in *qry_out ) {
            *collIds = cons( *r.COLL_ID, *collIds); 
        }
        *cntIdxOld = *cntIdx;
        if ( *cntIdxOld > 0 ) {
           if ( errorcode(msiGetMoreRows(*genQryInp,*qry_out,*cntIdx)) == EC_CAT_NO_ROWS_FOUND ) { *cntIdxOld = 0; }
        }
    }

    foreach(*collId in *collIds) {
        if ( errormsg( rdmIndexCollection( *collId, *elasticIndexURL ), *errmsg) != 0 ) {
            rdmLog(LOG_ERR, 'rdmIndexAllCollections', 'failed to index collection id:' ++ *collId ++ ' error: ' ++ *errmsg);
        }
    }
}

#-----------------------------------------------------------------------
# rdmIndexAllUsers: (re)index users in the system or fail the previous
#                  indexing operation (i.e. with 'tobeindexed' attributed)
#
# [Input]
#  - *elasticIndexURL: the 'rdm' elastic index URL 
#  - *full: set 'true' for reindexing all system users; otherwiser only
#           the users with attribute 'tobeindexed' 
#-----------------------------------------------------------------------
rdmIndexAllUsers( *elasticIndexURL, *full ) {

    *qry_attr = "USER_NAME";
    *qry_cond = "META_USER_ATTR_NAME = 'tobeindexed' AND META_USER_ATTR_VALUE = '1'";

    if ( bool(*full) ) {
        # all RDM users have homeOrgansiation attribute
        *qry_cond = "META_USER_ATTR_NAME = 'homeOrganisation'";
    }
 
    msiMakeGenQuery(*qry_attr, *qry_cond, *genQryInp);
    msiExecGenQuery(*genQryInp, *qry_out);
    msiGetContInxFromGenQueryOut(*qry_out, *cntIdx); 
 
    *cntIdxOld = 1;

    *userNames = list(); 
    while( *cntIdxOld > 0 ) { 
        foreach(*r in *qry_out ) {
            *userNames = cons( *r.USER_NAME, *userNames); 
        }
        *cntIdxOld = *cntIdx;
        if ( *cntIdxOld > 0 ) {
           if ( errorcode(msiGetMoreRows(*genQryInp,*qry_out,*cntIdx)) == EC_CAT_NO_ROWS_FOUND ) { *cntIdxOld = 0; }
        }
    }

    foreach(*userName in *userNames) {
        if ( errormsg( rdmIndexUser( *userName, *elasticIndexURL ), *errmsg) != 0 ) {
            rdmLog(LOG_ERR, 'rdmIndexAllUsers', 'failed to index user:' ++ *userName ++ ' error: ' ++ *errmsg);
        }
    }
}
