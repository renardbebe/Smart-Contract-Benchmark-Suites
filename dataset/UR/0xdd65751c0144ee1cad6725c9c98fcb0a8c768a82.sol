 

pragma solidity >=0.4.22 <0.6.0;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; 
}

contract TokenERC20 {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

    mapping(address => uint256[]) public keySearch;
    mapping(address => bool) public keyExists;
    mapping(bytes32 => bool) private pExists;
    mapping(bytes32 => uint256) private pSearch;

    address public contractOwner;

    string[]    public annotation;
    string[]    public externalUid;
    address[]   public fromAddress;
    address[]   public toAddress;
    uint256[]   public numberOfTokens;
    string[]    public action;
    
    
    

     
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol,
        address contractOwnerC,
        address defaultReturnAddress
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        contractOwner = contractOwnerC;
        string[]    memory tmpAnnotation;
        string[]    memory tmpExternalUid;
        address[]   memory tmpFromAddress;
        address[]   memory tmpToAddress;
        uint256[]   memory tmpNumberOfTokens;
        string[]    memory tmpAction;
        annotation = tmpAnnotation;
        externalUid = tmpExternalUid;
        action = tmpAction;
        fromAddress = tmpFromAddress;
        toAddress = tmpToAddress;
        numberOfTokens = tmpNumberOfTokens;
         
        cBAList.push(cashBackAddressObj({cba:defaultReturnAddress, cbaActive:false, bankUid:"no match, default value" , bankUIDActive:false, expired:true}));
        cBAStatusMessage[contractOwner].push("default value, not intended for use");
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != address(0x0));
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
    
    
    function collapseInput(string memory _in) private pure returns (bytes32){
        return keccak256(abi.encode (_in));
    }    
    
    function testPExists(string memory _in) public view returns (bool){
        return pExists[collapseInput(_in)];
    }
    
    function getPSearch(string memory _in) public view returns (uint256){
        return pSearch[collapseInput(_in)];
    }
    
    
     
    function addAnnotation(
            string memory tmpAnnotation,
            string memory tmpExternalUid,
            address tmpFromAddress,
            address tmpToAddress,
            uint256 tmpNumberOfTokens,
            address keyIndex,
            string memory tmpAction
        ) private {
        require(msg.sender == contractOwner);
        bytes32 tmpPKey = collapseInput(tmpExternalUid);
        require(!pExists[tmpPKey]); 
        uint256 id = annotation.length;
        pExists[tmpPKey] = true;
        pSearch[tmpPKey] = id;
        if (!keyExists[keyIndex]) {
            keyExists[keyIndex] = true;
            uint256[] memory tmpArr;
            keySearch[keyIndex]= tmpArr;
        }
        keySearch[keyIndex].push(id);
        annotation.push(tmpAnnotation);
        externalUid.push(tmpExternalUid);
        fromAddress.push(tmpFromAddress);
        toAddress.push(tmpToAddress);
        action.push(tmpAction);
        numberOfTokens.push(tmpNumberOfTokens);
        
    }
    
    function getNumberOfAnnotations(address keyIndex) public view returns(uint256){
        uint256 num = 0;
        if(keyExists[keyIndex]){
            num = keySearch[keyIndex].length;
        }
        return num;
    }
    
    function annotatedTransfer(address to, uint tokens, string memory uid, string memory note) public{
        require(msg.sender == contractOwner);
        transfer(to, tokens);
        addAnnotation(note, uid, msg.sender, to, tokens, to, "send");
    }
    
    function annotatedBurn(address to, uint tokens, string memory uid, string memory note) public{
        require(msg.sender == contractOwner);
        burn(tokens);
        addAnnotation(note, uid, msg.sender, to, tokens, to, "burn");
    }
    
    function returnNote(uint256 trx) public view returns(
        string memory,
        string memory,
        address,
        address,
        uint256,
        string memory
        ){
        return(
            annotation[trx],
            externalUid[trx],
            fromAddress[trx],
            toAddress[trx],
            numberOfTokens[trx],
            action[trx]
            );
        }

    function annotationLength()public view returns(uint256){
        return annotation.length;
    }

    address public cashBackManager;
    mapping(address => uint256) public getCBAbyAddress;
    mapping(bytes32 => uint256) public getCBAbyBkUid;
    cashBackAddressObj[] public cBAList;
    mapping(address => string[]) public cBATransactionMessage;
    mapping(address => string[]) public cBAStatusMessage;
    mapping(address => uint256[]) public expiredAddress;
    mapping(bytes32 => uint256[]) public expiredBankUid;

    struct cashBackAddressObj{
        address cba;
        bool cbaActive;
        string bankUid;
        bool bankUIDActive;
        bool expired;
    }
    
    modifier restricted(){
        require(msg.sender == cashBackManager || msg.sender == contractOwner);
        _;
    }
    
    function setCashbackManager(address cba) public restricted{
        cashBackManager=cba;
    }

    function cBAListLength()public view returns(uint256){
        return cBAList.length;
    }
    
    function addCBA(address cba, bool cbaStatus, string memory bkUid, bool bkUidStatus, string memory statusMsg) public restricted{
        uint256 oldIdx=getCBAbyAddress[cba];
        if(oldIdx>0){
            expiredAddress[cba].push(oldIdx);
            cBAList[oldIdx].expired=true;
            cBAStatusMessage[cba].push("Expired Address");
        }
        bytes32 bkUidHash = collapseInput(bkUid);
        uint256 oldBkUidIndex = getCBAbyBkUid[bkUidHash];
        if(oldBkUidIndex > 0){
            expiredBankUid[bkUidHash].push(oldBkUidIndex);
            cBAList[oldBkUidIndex].expired=true;
            cBAStatusMessage[cba].push("Expired Bank UID");
        }
        getCBAbyAddress[cba]=cBAList.length;
        getCBAbyBkUid[bkUidHash]=cBAList.length;
        cBAList.push(cashBackAddressObj({cba:cba,cbaActive:cbaStatus,bankUid:bkUid,bankUIDActive:bkUidStatus, expired:false}));
        cBAStatusMessage[cba].push(statusMsg);
    }
    
    function getExpiredBkUidIndexes(string memory bkUid)public view returns (uint256[] memory){
        return expiredBankUid[collapseInput(bkUid)];
    }

    function getExpiredAddressIndexes(address cba)public view returns (uint256[] memory){
            return expiredAddress[cba];
    }

    function searchByBkUid(string memory bkUid) public view returns(uint256){
        return getCBAbyBkUid[collapseInput(bkUid)];
    }
    
    function getCBAStatusMessageLength(address cba) public view returns(uint256){
        return cBAStatusMessage[cba].length;
    }
    
    function getCBATransactionMessageLength(address cba) public view returns(uint256){
        return  cBATransactionMessage[cba].length;
    }
    
    function getCashBackObject(uint256 obj_id)public  view returns(address, bool, string memory, bool, bool){
        return(
                cBAList[obj_id].cba,
                cBAList[obj_id].cbaActive,
                cBAList[obj_id].bankUid,
                cBAList[obj_id].bankUIDActive,
                cBAList[obj_id].expired
            );
    }
    

    function annotatedCashBack(uint256 tk, address _to, string memory transferMsg) public{
        uint256 sndIdx = getCBAbyAddress[msg.sender];
        require(sndIdx>0 && cBAList[sndIdx].bankUIDActive);
        cBATransactionMessage[cBAList[sndIdx].cba].push(transferMsg);
        transfer(_to,tk);
    }
}