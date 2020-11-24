 

pragma solidity 0.4.18;

 
 
 

contract DisclosureManager {

	address public owner;

	struct Disclosure {
		bytes32 organization;
		bytes32 recipient;
		bytes32 location;
		bytes16 amount;
		bytes1 fundingType;
		bytes16 date;
		bytes32 purpose;
		bytes32 comment;
		uint amended;     
	}

	Disclosure[] public disclosureList;

	event disclosureAdded(
    uint rowNumber,
    bytes32 organization,
    bytes32 recipient,
    bytes32 location,
    bytes16 amount,
    bytes1 fundingType,
    bytes16 date,
    bytes32 purpose,
    bytes32 comment);

	function DisclosureManager() public {
		owner = msg.sender;
	}

	 
	 
	modifier isOwner() { if (msg.sender != owner) revert(); _ ;}

	 
	function getListCount() public constant returns(uint listCount) {
  	if (disclosureList.length > 0) {
			return disclosureList.length - 1;     
		} else {
			return 0;     
		}
	}
	 

	 
	function newEntry(bytes32 organization,
					  bytes32 recipient,
					  bytes32 location,
					  bytes16 amount,
					  bytes1 fundingType,
					  bytes16 date,
					  bytes32 purpose,
					  bytes32 comment) public isOwner() returns(uint rowNumber) {     

		 
		 
		if (disclosureList.length == 0) {
			 
			Disclosure memory nullEntry;
			disclosureList.push(nullEntry);
		}

		Disclosure memory disclosure;

		disclosure.organization = organization;
		disclosure.recipient = recipient;
		disclosure.location = location;
		disclosure.amount = amount;
		disclosure.fundingType = fundingType;
		disclosure.date = date;
		disclosure.purpose = purpose;
		disclosure.comment = comment;
		disclosure.amended = 0;

		 
		uint index = disclosureList.push(disclosure);    
		index = index - 1;

		 
		disclosureAdded(index, organization, recipient, location, amount, fundingType, date, purpose, comment);

		return index;    
	}

	 
	 
	function amendEntry(uint rowNumber,
						bytes32 organization,
						bytes32 recipient,
						bytes32 location,
						bytes16 amount,
						bytes1 fundingType,
						bytes16 date,
						bytes32 purpose,
						bytes32 comment) public isOwner() returns(uint newRowNumber) {     

		 
		if (rowNumber >= disclosureList.length) { revert(); }
		if (rowNumber < 1) { revert(); }
		if (disclosureList[rowNumber].amended > 0) { revert(); }     

		 
		Disclosure memory disclosure;

		disclosure.organization = organization;
		disclosure.recipient = recipient;
		disclosure.location = location;
		disclosure.amount = amount;
		disclosure.fundingType = fundingType;
		disclosure.date = date;
		disclosure.purpose = purpose;
		disclosure.comment = comment;
		disclosure.amended = 0;

		 
		uint index = disclosureList.push(disclosure);    
		index = index - 1;

		 
		disclosureList[rowNumber].amended = index;

		 
		disclosureAdded(index, organization, recipient, location, amount, fundingType, date, purpose, comment);    

		return index;    
	}

	 
	function pullRow(uint rowNumber) public constant returns(bytes32, bytes32, bytes32, bytes16, bytes1, bytes16, bytes32, bytes32, uint) {
		 
		if (rowNumber >= disclosureList.length) { revert(); }
		if (rowNumber < 1) { revert(); }
		 
		Disclosure memory entry = disclosureList[rowNumber];
		return (entry.organization, entry.recipient, entry.location, entry.amount, entry.fundingType, entry.date, entry.purpose, entry.comment, entry.amended);
	}

	 
	function pullEntry(uint rowNumber) public constant returns(bytes32, bytes32, bytes32, bytes16, bytes1, bytes16, bytes32, bytes32) {
		 
		if (rowNumber >= disclosureList.length) { revert(); }
		if (rowNumber < 1) { revert(); }
		 
		 
		if (disclosureList[rowNumber].amended > 0) return pullEntry(disclosureList[rowNumber].amended);
		 
		Disclosure memory entry = disclosureList[rowNumber];
		return (entry.organization, entry.recipient, entry.location, entry.amount, entry.fundingType, entry.date, entry.purpose, entry.comment);
		 
	}

}