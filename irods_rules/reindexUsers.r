reindexUsers {

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
            writeLine('stdout', 'failed to index user: ' ++ *userName);
            writeLine('stdout', *errmsg);
        }
    }
}

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

INPUT *elasticIndexURL=$"http://agaatvlinder.uci.ru.nl:9200/rdm",*full=$'false'
OUTPUT ruleExecOut
