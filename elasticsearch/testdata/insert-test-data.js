endpointElastic = 'http://localhost:9200/rdm/'
fs = require('fs')
request = require('request');

function sleep(delay) {
    var start = new Date().getTime();
    while (new Date().getTime() < start + delay);
}

function readFile(fileName, onSuccess) {
	fs.readFile(fileName, 'utf8', function (err,data) {
	  if (err) {
		return console.log(err);
	  }
	  var dataJson = JSON.parse(data);
	  onSuccess.apply(this, [dataJson]);
	});
}

function createUser(users, i) {	
	if (i < users.length) {
	    var user = users[i];
		var endPoint = endpointElastic + 'user' + '/' + user.irodsUserName;
		transformUser(user);		
		var putRequest = { url: endPoint, method: 'put', json: user};		
		request(putRequest, function(error, request, body) {
		   //console.log(body);
		   createUser(users, i + 1);
		});			
	}	
}

function createUsers(usersResponse) {	
	var users = usersResponse.users;
	createUser(users, 0);
	console.log('Creating ' + users.length + ' users');
}

function createCollection(collections, i) {	
	if (i < collections.length) {
		var collection = collections[i];
		var collId =  collection.collId;
		var index = 'collection';
		var parentParameter = '';
		if (collection.parentVersion) {
			index = 'collection_version';
			parentParameter = '?parent=' + collection.parentVersion;
		}
		var endPoint = endpointElastic + index + '/' + collection.collId + parentParameter;
		transformCollection(collection);		
		var putRequest = { url: endPoint, method: 'put', json: collection};
		request(putRequest, function(error, request, body) {
			// console.log(body);
			createCollection(collections, i + 1);
		});			
	}	
}

function enrichCollectionsWithParentVersions(collections) {
	var collectionsByIdentifier = {};
	for (var i = 0; i < collections.length; i++) {
		var collection = collections[i];
		if (!collectionsByIdentifier[collection.collectionIdentifier]) {
			collectionsByIdentifier[collection.collectionIdentifier] = [];			
		}		
		collectionsByIdentifier[collection.collectionIdentifier].push(collection);
	}
	//console.log(JSON.stringify(collectionsByIdentifier['di.dcc.DAC_2016.00215_773']));
	for (var collectionIdentifier in collectionsByIdentifier) {		
		var collectionsSameIdentifier = collectionsByIdentifier[collectionIdentifier];
		var parentCollection = null;
		// console.log('parent version found' + typeof collectionsSameIdentifier);
		for (var i = 0; i < collectionsSameIdentifier.length; i++) {						
			var collectionSameIdentifier = collectionsSameIdentifier[i];			
			if (!collectionSameIdentifier.versionNumber) {
				parentCollection = collectionSameIdentifier;
			}
		}
		for (var i = 0; i < collectionsSameIdentifier.length; i++) {
			var collectionSameIdentifier = collectionsSameIdentifier[i];
			if (collectionSameIdentifier.versionNumber) {
				collectionSameIdentifier.parentVersion = parentCollection.collId;
			}
		}		
	}
	// console.log(JSON.stringify(collectionsByIdentifier));
}

function createCollections(collectionsResponse) {	
	var collections = collectionsResponse.collections;	
	enrichCollectionsWithParentVersions(collections);
	createCollection(collections, 0);
	console.log('Creating ' + collections.length + ' collections');
}

function transformUser(user) {
	/*
	renameAttribute(user, 'attributeLastUpdatedDateTime', 'attributesUpdated');
	renameAttribute(user, 'homeOrganisation', 'organisation');
	renameAttribute(user, 'organisationUnit', 'organisationalUnits');	
	renameAttribute(user, 'personalWebsiteUrl', 'personalWebsite');	
	delete(user.irodsUserName);
	*/
}

function transformCollection(collection) {
	/*
	renameAttribute(collection, 'attributeLastUpdatedDateTime', 'attributesUpdated');
	renameAttribute(collection, 'associatedPublication', 'associatedPublications');
	for (var i in collection.associatedPublications) {
		var associatedPublication = collection.associatedPublications[i];
	}
	
	renameAttribute(collection, 'contributor', 'contributors');
	renameAttribute(collection, 'creationDateTime', 'created');
	renameAttribute(collection, 'creatorList', 'creators');		
	renameAttribute(collection, 'descriptionAbstract', 'abstract');	
	renameAttribute(collection, 'ethicalApprovalIdentifier', 'ethicalApprovals');	
	for (var i in collection.ethicalApprovals) {
		var ethicalApproval = collection.ethicalApprovals[i];
		renameAttribute(ethicalApproval, "caseId", "id");
		renameAttribute(ethicalApproval, "reviewBoardName", "reviewBoard");
	}
	collection.identifiers = [];
	var identifier = null;
	if (collection.identifierDOI) {
		identifier = { id: collection.identifierDOI, type: "DOI"};
		collection.identifiers.push(identifier);		
	}
    if (collection.identifierEPIC) {
	   identifier = { id: collection.identifierEPIC, type: "EPIC"};
	   collection.identifiers.push(identifier);
	}
	collection.keywords = [];
	renameAttribute(collection, 'keyword_MeSH_2015', 'keywords_MeSH_2015');
	renameAttribute(collection, 'keyword_SFN_2013', 'keywords_SFN_2013');
	for (var i in collection.keyword_freetext) {		
		var keyword = { id: collection.keyword_freetext[i]};
		collection.keywords.push(keyword);
	}	
	
	renameAttribute(collection, 'lastClosedDateTime', 'closed');
	renameAttribute(collection, 'manager', 'managers');
	renameAttribute(collection, 'contributor', 'contributors');
	renameAttribute(collection, 'viewer', 'viewers');
	renameAttribute(collection, 'preservationTime', 'preservationTimeYear');
	renameAttribute(collection, 'quotaInBytes', 'quota');
	renameAttribute(collection, 'quotaInBytes', 'quota');
	renameAttribute(collection, 'sizeInBytes', 'size');
	*/
	delete(collection.associatedRDC);
	delete(collection.associatedDAC);
	delete(collection.associatedDSC);
    delete(collection.collId);
	delete(collection.collName);
	delete(collection.collectionIdentifier);
	delete(collection.identifierDOI);
	delete(collection.identifierEPIC);
	delete(collection.keyword_MeSH_2015);
	delete(collection.keyword_SFN_2013);
	delete(collection.keyword_freetext);
	delete(collection.nextVersionId);
	delete(collection.latestVersionId);
}

function renameAttribute(object, oldName, newName) {
	object[newName] = object[oldName];
	delete object[oldName];
}

readFile('users.json', createUsers);
readFile('collections.json', createCollections);