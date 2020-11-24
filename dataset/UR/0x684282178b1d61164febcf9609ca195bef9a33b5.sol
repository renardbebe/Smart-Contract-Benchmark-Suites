 

 

 

 
 
 
 
 
 
contract tokenRecipient {
    function receiveApproval(address _from,      
                             uint256 _value,     
                             address _share,     
                             bytes _extraData);  
}

contract Corporation {

     
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
     

     
     
    address[] public shareholder;
     
    mapping (address => uint256) public shareholderID;
     
     
    address[] activeShareholdersArray;
     
    mapping (address => uint256) public balanceOf;
     
    mapping (address => mapping (address => uint256)) public allowance;

     
     
    function Corporation () {  
        uint256 initialSupply = 12000;  
        balanceOf[msg.sender] = initialSupply;  
        totalSupply = initialSupply;   
        name = "shares";  
        symbol = "sh";  
        decimals = 0;  

         
        shareholderID[this] = shareholder.push(this)-1;  
        shareholderID[msg.sender] = shareholder.push(msg.sender)-1;  
        activeShareholdersArray.push(msg.sender);  
    }

     

     
    event Transfer(address indexed from, address indexed to, uint256 value);

    function getCurrentShareholders() returns (address[]){
        delete activeShareholdersArray;
        for (uint256 i=0; i < shareholder.length; i++){
            if (balanceOf[shareholder[i]] > 0){
                activeShareholdersArray.push(shareholder[i]);
            }
            } return activeShareholdersArray;
        }

     
    function getBalanceByAdress(address _address) returns (uint256) {
        return balanceOf[_address];
    }

    function getMyShareholderID() returns (uint256) {
        return shareholderID[msg.sender];
    }

    function getShareholderAdressByID(uint256 _id) returns (address){
        return shareholder[_id];
    }

    function getMyShares() returns (uint256) {
        return balanceOf[msg.sender];
    }


     
    function transfer(address _to, uint256 _value) {
         
        if (_value < 1) throw;
        if (this == _to) throw;  
        if (balanceOf[msg.sender] < _value) throw;  

         
        balanceOf[msg.sender] -= _value;  
        balanceOf[_to] += _value;        

         
        if (shareholderID[_to] == 0){  
            shareholderID[_to] = shareholder.push(_to)-1;
        }

         
        Transfer(msg.sender, _to, _value);
    }

     
    function approveAndCall(address _spender,  
                            uint256 _value,  
                            bytes _extraData)  
    returns (bool success) {
         
         
         
         
         
        allowance[msg.sender][_spender] = _value;
         
         
        tokenRecipient spender = tokenRecipient(_spender);
         
         
         
        spender.receiveApproval(msg.sender,  
                                _value,      
                                this,        
                                _extraData); 
        return true;
    }

     
    function transferFrom(address _from,
                          address _to,
                          uint256 _value)
    returns (bool success) {

         
         
        if (_value < 1) throw;
         
        if (this == _to) throw;
         
        if (balanceOf[_from] < _value) throw;

         
        if (_value > allowance[_from][msg.sender]) throw;

         
        if (shareholderID[_to] == 0){
            shareholderID[_to] = shareholder.push(_to)-1;  
        }

         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;

         
        allowance[_from][msg.sender] -= _value;
         
        Transfer(_from, _to, _value);

        return true;
    }

     
    function () {
        throw;      
    }

     
     
     

     
     
    string[] public proposalText;
     
    mapping (uint256 => mapping (address => bool)) voted;
     
     
     
    mapping (uint256 => address[]) public votes;
     
    mapping (uint256 => uint256) public deadline;
     
    mapping (uint256 => uint256) public results;
     
    mapping (address => uint256[]) public proposalsByShareholder;


    event ProposalAdded(uint256 proposalID,
                        address initiator,
                        string description,
                        uint256 deadline);

    event VotingFinished(uint256 proposalID, uint256 votes);

    function makeNewProposal(string _proposalDescription,
                             uint256 _debatingPeriodInMinutes)
    returns (uint256){
         
         
        if (balanceOf[msg.sender] < 1) throw;

        uint256 id = proposalText.push(_proposalDescription)-1;
        deadline[id] = now + _debatingPeriodInMinutes * 1 minutes;

         
        proposalsByShareholder[msg.sender].push(id);

         
        votes[id].push(msg.sender);
        voted[id][msg.sender] = true;

        ProposalAdded(id, msg.sender, _proposalDescription, deadline[id]);

        return id;  
    }

    function getMyProposals() returns (uint256[]){
        return proposalsByShareholder[msg.sender];
    }

    function voteForProposal(uint256 _proposalID) returns (string) {

         
        if (balanceOf[msg.sender] < 1) return "no shares, vote not accepted";

         
        if (voted[_proposalID][msg.sender]){
            return "already voted, vote not accepted";
        }

         
        if (now > deadline[_proposalID] ){
            return "vote not accepted after deadline";
        }

         
        votes[_proposalID].push(msg.sender);
        voted[_proposalID][msg.sender] = true;
        return "vote accepted";
    }

     
     
    function countVotes(uint256 _proposalID) returns (uint256){

         
        if (now < deadline[_proposalID]) throw;

         
        if (results[_proposalID] > 0) return results[_proposalID];

         
        uint256 result = 0;
        for (uint256 i = 0; i < votes[_proposalID].length; i++){

            address voter = votes[_proposalID][i];
            result = result + balanceOf[voter];
        }

         
         
        VotingFinished(_proposalID, result);

        return result;
    }

}