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
		   console.log(body);
		   createUser(users, i + 1);
		});			
	}	
}

function createUsers(usersResponse) {	
	var users = usersResponse.users;
	createUser(users, 0);
}

function createCollection(collections, i) {	
	if (i < collections.length) {
		var collection = collections[i];
		var endPoint = endpointElastic + 'collection' + '/' + collection.collId;
		transformCollection(collection);		
		var putRequest = { url: endPoint, method: 'put', json: collection};		
		request(putRequest, function(error, request, body) {
			console.log(body);
			createCollection(collections, i + 1);
		});			
	}	
}

function createCollections(collectionsResponse) {	
	var collections = collectionsResponse.collections;	
	createCollection(collections, 0);
}

function transformUser(user) {
	renameAttribute(user, 'attributeLastUpdatedDateTime', 'attributesUpdated');
	renameAttribute(user, 'homeOrganisation', 'organisation');
	renameAttribute(user, 'organisationUnit', 'organisationalUnits');	
	renameAttribute(user, 'personalWebsiteUrl', 'personalWebsite');	
	delete(user.irodsUserName);
}

function transformCollection(collection) {
	renameAttribute(collection, 'attributeLastUpdatedDateTime', 'attributesUpdated');
	renameAttribute(collection, 'associatedPublication', 'associatedPublications');
	for (var i in collection.associatedPublications) {
		var associatedPublication = collection.associatedPublications[i];
		//
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
	for (var i in collection.identifierDOI) {		
		var identifier = { id: collection.identifierDOI[i], type: "DOI"};
		collection.identifiers.push(identifier);
	}	
	for (var i in collection.identifierEPIC) {		
		var identifier = { id: collection.identifierEPIC[i], type: "EPIC"};
		collection.identifiers.push(identifier);
	}
	collection.keywords = [];
	for (var i in collection.keyword_MeSH_2015) {		
		var keyword = { id: collection.keyword_MeSH_2015[i], vocabulary: "MeSH_2015" };
		collection.keywords.push(keyword);
	}	
	for (var i in collection.keyword_SFN_2013) {		
		var keyword = { id: collection.keyword_SFN_2013[i], vocabulary: "SFN_2013" };
		collection.keywords.push(keyword);
	}
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
	delete(collection.latestVersionId);
}

function renameAttribute(object, oldName, newName) {
	object[newName] = object[oldName];
	delete object[oldName];
}

readFile('users.json', createUsers);
readFile('collections.json', createCollections);