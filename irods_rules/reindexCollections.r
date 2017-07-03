reindexCollections {

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
            writeLine('stdout', 'failed to index collection id: ' ++ *collId);
            writeLine('stdout', *errmsg);
        }
    }
}

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

INPUT *elasticIndexURL=$"http://agaatvlinder.uci.ru.nl:9200/rdm",*full=$'false'
OUTPUT ruleExecOut
