 

pragma solidity ^0.5.12;
pragma experimental ABIEncoderV2;
 
 
contract electionList{
	string public hashHead;
     
	string[] public councilList;
	uint256 public councilNumber;
}
contract localElection{
    address payable public owner;
    string public encryptionPublicKey;  
    bool public isRunningElection = false;
	 
	 
	 
	mapping(address => bool) public approvedVoteBox;
	
	 
	 
	 
	 
	 
	 
	mapping(uint256 => bool) public voterList;
	mapping(uint256 => uint256) public usedPhoneNumber;
	mapping(uint256 => mapping(string => bool)) public councilVoterList;
	mapping(string => uint) public councilVoterNumber;
	
	 
	 
	 
	 
	 
	 
	mapping(uint256 => string) private voteListByVoter; 
	mapping(string => string[]) private votes;  
	mapping(address => string[]) private voteByVotebox;  
	mapping(string => bool) private voteDictionary;  
	mapping(string => address) public invalidVotes;
	
	address public dbAddress;
	
	constructor(address electionDBaddr,string memory pKey) public{
	    owner = msg.sender;
	    dbAddress = electionDBaddr;
	    encryptionPublicKey = pKey;
	}
	
	function() external payable { 
		 
		 
		if(address(this).balance >= msg.value && msg.value >0) 
            owner.transfer(msg.value);
	}
	 
	function withdrawAll() public payable{
	    if(address(this).balance >0) owner.transfer(address(this).balance);
	}
	function addVoteBox(address box) public {
		if(msg.sender != owner) revert();
		approvedVoteBox[box] = true;
	}
	function removeVoteBox(address box) public {
		if(msg.sender != owner) revert();
		approvedVoteBox[box] = false;
		 
		electionList db = electionList(dbAddress);
		for(uint i=0;i<db.councilNumber();i++){
		    for(uint a=0;a<voteByVotebox[box].length;a++){
		        if(bytes(voteByVotebox[box][a]).length >0){
		            invalidVotes[voteByVotebox[box][a]] = msg.sender;
		        }
		    }
		}
	}
	function getVoteboxVoteCount(address box) public view returns(uint256){
	    return voteByVotebox[box].length;
	}
	function getCouncilVoteCount(string memory council) public view returns(uint256){
	    return votes[council].length;
	}
	function startElection() public {
	    if(msg.sender != owner) revert();
	    isRunningElection = true;
	}
	function stopElection() public {
	    if(msg.sender != owner) revert();
	    isRunningElection = false;
	}
	 
	 
	 
	 
	 
	function getVoterID(string memory name, string memory HKID) 
		public view returns(uint256){
		electionList db = electionList(dbAddress);
		if(!checkHKID(HKID)) return 0;
		return uint256(sha256(joinStrToBytes(db.hashHead(),HKID,"")));
	}
	 
	function getEmailHash(string memory email)
		public view returns(uint256){
		 
		electionList db = electionList(dbAddress);
		return uint256(sha256(joinStrToBytes(db.hashHead(),email,"")));
	}
	 
	function register(uint256 voterID, uint256 hashedEmail, string memory council) 
		public returns(bool){
		require(isRunningElection);
		require(approvedVoteBox[msg.sender]);
		 
		 
		 
		if(voterList[voterID]) deregister(voterID);
		 
			 
		if(usedPhoneNumber[hashedEmail] > 0)
			deregister(usedPhoneNumber[hashedEmail]);
		voterList[voterID] = true;
		 
		usedPhoneNumber[hashedEmail] = voterID;
		councilVoterList[voterID][council] = true;
		councilVoterNumber[council]++;
		return true;
	}
	function deregister(uint256 voterID) 
		internal returns(bool){
		require(isRunningElection);
		voterList[voterID] = false;	
		electionList db = electionList(dbAddress);
		for(uint i=0;i<db.councilNumber();i++){
			 
			if(councilVoterList[voterID][db.councilList(i)]){
				councilVoterList[voterID][db.councilList(i)] = false;
				councilVoterNumber[db.councilList(i)]--;
			}
		}
		if(bytes(voteListByVoter[voterID]).length >0){
			invalidVotes[voteListByVoter[voterID]] = msg.sender;
			delete voteListByVoter[voterID];
		}
		return true;
	}
	 
	function isValidVoter(uint256 voterID, uint256 hashedEmail, string memory council) 
		public view returns(bool){
		if(!voterList[voterID]) return false;
		 
		if(usedPhoneNumber[hashedEmail] == 0 || usedPhoneNumber[hashedEmail] != voterID)
			return false;
		if(!councilVoterList[voterID][council]) return false;
		return true;
	}
	function isVoted(uint256 voterID) public view returns(bool){
		if(bytes(voteListByVoter[voterID]).length >0) return true;
		return false;
	}
	 
	function submitVote(uint256 voterID, uint256 hashedEmail, 
	    string memory council, string memory singleVote) public returns(bool){
		require(isRunningElection);
		require(approvedVoteBox[msg.sender]);
		 
		 
		 
		require(isValidVoter(voterID,hashedEmail,council));
		require(!isVoted(voterID));  
		require(!voteDictionary[singleVote]);
		voteListByVoter[voterID] = singleVote;
		votes[council].push(singleVote);
		voteByVotebox[msg.sender].push(singleVote);
		voteDictionary[singleVote] = true;
		return true;
	}
	
	function registerAndVote(uint256 voterID, uint256 hashedEmail, 
	    string memory council, string memory singleVote) public returns(bool){
	    require(isRunningElection);
		require(approvedVoteBox[msg.sender]);
	    require(!voterList[voterID]);
	    require(usedPhoneNumber[hashedEmail] ==0);
	    require(!voteDictionary[singleVote]);
	    voterList[voterID] = true;
		 
		usedPhoneNumber[hashedEmail] = voterID;
		councilVoterList[voterID][council] = true;
		councilVoterNumber[council]++;
		voteListByVoter[voterID] = singleVote;
		votes[council].push(singleVote);
		voteByVotebox[msg.sender].push(singleVote);
		voteDictionary[singleVote] = true;
	    return true;
	}
	
	function getResult(string memory council) public view returns(uint, uint, uint, uint, 
		string[] memory, string[] memory){
		require(!isRunningElection);
		 
		uint totalVoteCount = votes[council].length;
		uint validVoteCount;
		 
		for(uint i=0;i<totalVoteCount;i++){
			string memory singleVote = votes[council][i];
			if(invalidVotes[singleVote] == address(0)){
			    validVoteCount++;   
			}
			 
		}
		 
		string[] memory validVoteIndex = new string[](validVoteCount);
		string[] memory invalidVoteIndex = new string[](totalVoteCount-validVoteCount);
		uint a=0;
		for(uint i=0;i<totalVoteCount && (a<validVoteCount || validVoteCount==0);i++){
			string memory singleVote = votes[council][i];
			if(invalidVotes[singleVote] == address(0)){
			    validVoteIndex[a++] = singleVote;
			}else{
			    invalidVoteIndex[i-a] = singleVote;
			}
		}
		return (councilVoterNumber[council],totalVoteCount,validVoteCount,
		    totalVoteCount-validVoteCount,validVoteIndex,invalidVoteIndex);
	}
	
	function joinStrToBytes(string memory _a, string memory _b, string memory _c) 
		internal pure returns (bytes memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
		bytes memory _bc = bytes(_c);
        string memory ab = new string(_ba.length + _bb.length + _bc.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
		for (uint i = 0; i < _bc.length; i++) bab[k++] = _bc[i];		
         
        return bab;
    }
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint j = _i;
		uint len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint k = len - 1;
		while (_i != 0) {
			bstr[k--] = byte(uint8(48 + _i % 10));
			_i /= 10;
		}
		return string(bstr);
	}
	 
	function checkHKID(string memory HKID) 
		internal pure returns(bool){
		bytes memory b = bytes(HKID);
		if(b.length !=8 && b.length !=9) return false;
		uint256 checkDigit = 0;
		uint256 power = 9;
		if(b.length ==8){
			checkDigit += (36*power);
			power--;
		}
		for(uint i=0;i<b.length;i++){
			uint digit = uint8(b[i]);
			if(i>(b.length-8) && i<(b.length-1)){
				 
				if(digit < 48 || digit > 57) return false;
			}
			if(digit >=48 && digit<=57) checkDigit += ((digit-48)*power);  
			else if(digit >=65 && digit<=90) checkDigit += ((digit-55)*power);  
			else return false;
			power--;
		}
		if(checkDigit % 11 == 0) return true;
		return false;
	}
}