 

pragma solidity ^0.4.24;

 
 
 
 
 
 
 


 
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract Ownable {

     
    event OwnershipTransferred(address indexed _from, address indexed _to);
    event SubmitPrps(ProposalType indexed _prpsType);
    event SignPrps(uint256 indexed _prpsIdx, ProposalType indexed _prpsType, address indexed _from);

     
    enum ProposalType {
        freeze,
        unfreeze,
        transferOwner
    }
     
    struct Proposal {
        ProposalType prpsType;
        address fromAddr;
        address toAddr;
        mapping(address => bool) signed;
        bool finalized;
    }
     
    uint256 public requiredSignNum;
     
    address[] public owners;
     
    Proposal[] public proposals;
     
    mapping(address => bool) public isOwnerMap;

    constructor() public{
    }

     
    modifier isOwner{
        require(isOwnerMap[msg.sender], "");
        _;
    }
     
    modifier multiSig(uint256 _prpsIdx) {
         
        require(signOwnerCount(_prpsIdx) >= requiredSignNum, "");
         
        require(proposals[_prpsIdx].finalized == false, "");
        _;
    }
     
    modifier isPrpsExists(uint256 _prpsIdx) {
        require(_prpsIdx >= 0, "");
        require(_prpsIdx < proposals.length, "");
        _;
    }
    modifier checkOwner(address _fromAddr, address _toAddr) {
        require(_toAddr != address(0), "");
        require(_toAddr != msg.sender, "");
        require(_fromAddr != msg.sender, "");
        _;
    }
     
    modifier checkPrpsType(ProposalType _prpsType) {
        require(_prpsType == ProposalType.freeze || _prpsType == ProposalType.unfreeze || _prpsType == ProposalType.transferOwner, "");
        _;
    }
     
    modifier checkSignPrps(uint256 _prpsIdx) {
         
        require(proposals[_prpsIdx].finalized == false, "");
         
        require(proposals[_prpsIdx].signed[msg.sender] == false, "");
        _;
    }


     
    function submitProposal(ProposalType _prpsType, address _fromAddr, address _toAddr) public isOwner checkOwner(_fromAddr, _toAddr) checkPrpsType(_prpsType) {
        Proposal memory _proposal;
        _proposal.prpsType = _prpsType;
        _proposal.finalized = false;
        _proposal.fromAddr = _fromAddr;
        _proposal.toAddr = _toAddr;
        proposals.push(_proposal);
        emit SubmitPrps(_prpsType);
    }

     
    function signProposal(uint256 _prpsIdx) public isOwner isPrpsExists(_prpsIdx) checkSignPrps(_prpsIdx){
        proposals[_prpsIdx].signed[msg.sender] = true;
        emit SignPrps(_prpsIdx, proposals[_prpsIdx].prpsType, msg.sender);
    }

     
    function signOwnerCount(uint256 _prpsIdx) public view isPrpsExists(_prpsIdx) returns(uint256) {
        uint256 signedCount = 0;
        for(uint256 i = 0; i < owners.length; i++) {
            if(proposals[_prpsIdx].signed[owners[i]] == true){
                signedCount++;
            }
        }
        return signedCount;
    }

     
    function getProposalCount() public view returns(uint256){
        return proposals.length;
    }
    
     
    function getProposalInfo(uint256 _prpsIdx) public view isPrpsExists(_prpsIdx) returns(ProposalType _prpsType, uint256 _signedCount, bool _isFinalized, address _fromAddr, address _toAddr){

        Proposal memory _proposal = proposals[_prpsIdx];
        uint256 signCount = signOwnerCount(_prpsIdx);
        return (_proposal.prpsType, signCount, _proposal.finalized, _proposal.fromAddr, _proposal.toAddr);
    }

     
    function transferOwnership(uint256 _prpsIdx) public isOwner isPrpsExists(_prpsIdx) multiSig(_prpsIdx) {

         
        require(proposals[_prpsIdx].prpsType == ProposalType.transferOwner, "");
        address oldOwnerAddr = proposals[_prpsIdx].fromAddr;
        address newOwnerAddr = proposals[_prpsIdx].toAddr;
        require(oldOwnerAddr != address(0), "");
        require(newOwnerAddr != address(0), "");
        require(oldOwnerAddr != newOwnerAddr, "");
        for(uint256 i = 0; i < owners.length; i++) {
            if( owners[i] == oldOwnerAddr){
                owners[i] = newOwnerAddr;
                delete isOwnerMap[oldOwnerAddr];
                isOwnerMap[newOwnerAddr] = true;
            }
        }
        proposals[_prpsIdx].finalized = true;
        emit OwnershipTransferred(oldOwnerAddr, newOwnerAddr);
    }

}



 
contract Pausable is Ownable {

    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused {
        require(!paused, "");
        _;
    }
    modifier whenPaused {
        require(paused, "");
        _;
    }

     
    function pause() public isOwner whenNotPaused returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

     
    function unpause() public isOwner whenPaused returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }

}


 
contract ERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
     
    event Approval(address indexed _from, address indexed _to, uint256 _amount);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
}



 
contract ERC20Token is ERC20 {

    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 public totalToken;

    function totalSupply() public view returns (uint256) {
        return totalToken;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "");
        return balances[_owner];
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "");
        require(balances[_from] >= _value, "");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "");
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        require(_from != address(0), "");
        require(_to != address(0), "");
        require(_value > 0, "");
        require(balances[_from] >= _value, "");
        require(allowed[_from][msg.sender] >= _value, "");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool){
        require(_spender != address(0), "");
        require(_value > 0, "");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256){
        require(_owner != address(0), "");
        require(_spender != address(0), "");
        return allowed[_owner][_spender];
    }

}


 
contract LVECoin is ERC20Token, Pausable {

    string public  constant name        = "LVECoin";
    string public  constant symbol      = "LVE";
    uint256 public constant decimals    = 18;
     
    uint256 private initialToken        = 2000000000 * (10 ** decimals);
    
     
    event Freeze(address indexed _to);
     
    event Unfreeze(address indexed _to);
    event WithdrawalEther(address indexed _to, uint256 _amount);
    
     
    mapping(address => bool) public freezeAccountMap;  
     
    address private walletAddr;
     
    uint256 private signThreshold       = 3;

    constructor(address[] _initOwners, address _walletAddr) public{
        require(_initOwners.length == signThreshold, "");
        require(_walletAddr != address(0), "");

         
        requiredSignNum = _initOwners.length.div(2).add(1);
        owners = _initOwners;
        for(uint i = 0; i < _initOwners.length; i++) {
            isOwnerMap[_initOwners[i]] = true;
        }

        totalToken = initialToken;
        walletAddr = _walletAddr;
        balances[msg.sender] = totalToken;
        emit Transfer(0x0, msg.sender, totalToken);
    }


     
    modifier freezeable(address _addr) {
        require(_addr != address(0), "");
        require(!freezeAccountMap[_addr], "");
        _;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused freezeable(msg.sender) returns (bool) {
        require(_to != address(0), "");
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused freezeable(msg.sender) returns (bool) {
        require(_from != address(0), "");
        require(_to != address(0), "");
        return super.transferFrom(_from, _to, _value);
    }
    function approve(address _spender, uint256 _value) public whenNotPaused freezeable(msg.sender) returns (bool) {
        require(_spender != address(0), "");
        return super.approve(_spender, _value);
    }

     
    function freezeAccount(uint256 _prpsIdx) public isOwner isPrpsExists(_prpsIdx) multiSig(_prpsIdx) returns (bool) {

         
        require(proposals[_prpsIdx].prpsType == ProposalType.freeze, "");
        address freezeAddr = proposals[_prpsIdx].toAddr;
        require(freezeAddr != address(0), "");
         
        proposals[_prpsIdx].finalized = true;
        freezeAccountMap[freezeAddr] = true;
        emit Freeze(freezeAddr);
        return true;
    }
    
     
    function unfreezeAccount(uint256 _prpsIdx) public isOwner isPrpsExists(_prpsIdx) multiSig(_prpsIdx) returns (bool) {

         
        require(proposals[_prpsIdx].prpsType == ProposalType.unfreeze, "");
        address freezeAddr = proposals[_prpsIdx].toAddr;
        require(freezeAddr != address(0), "");
         
        proposals[_prpsIdx].finalized = true;
        freezeAccountMap[freezeAddr] = false;
        emit Unfreeze(freezeAddr);
        return true;
    }

     
    function() public payable {
        require(msg.value > 0, "");
        walletAddr.transfer(msg.value);
        emit WithdrawalEther(walletAddr, msg.value);
    }

}