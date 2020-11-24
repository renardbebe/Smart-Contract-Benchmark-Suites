 

pragma solidity ^0.5.12;

 

 
contract ERC223ReceivingContract {
    function tokenFallback(address from, uint value, bytes memory _data) public;
}

 
contract ERC223Interface {
    function balanceOf(address who)public view returns (uint);
    function transfer(address to, uint value)public returns (bool success);
    function transfer(address to, uint value, bytes memory data)public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value);
}

 
contract UpgradedStandardToken{
    function transferByHolder(address to, uint tokens) external;
}

 
contract Authenticity{
    function getAddress(address contratAddress) public view returns (bool);
}

 
library safeMath {
    
     
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
     
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    
     
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    
     
    function div(uint256 a, uint256 b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

 
contract Ownable {
    address public owner;
    
    constructor() internal{
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

 
contract BlackList is Ownable{
    
    mapping (address => bool) internal isBlackListed;
    
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
    
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }
    
     
    function addBlackList (address _evilUser) public onlyOwner {
        require(!isBlackListed[_evilUser]);
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

     
    function removeBlackList (address _clearedUser) public onlyOwner {
        require(isBlackListed[_clearedUser]);
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }
}

 
contract BasicERC223 is BlackList,ERC223Interface {
    
    using safeMath for uint;
    uint8 public basisPointsRate;
    uint public minimumFee;
    uint public maximumFee;
    address[] holders;
    
    mapping(address => uint) internal balances;
    
    event Transfer(address from, address to, uint256 value, bytes data, uint256 fee);
    
     
    function isContract(address _address) internal view returns (bool is_contract) {
        uint length;
        require(_address != address(0));
        assembly {
            length := extcodesize(_address)
        }
        return (length > 0);
    }
    
     
    function calculateFee(uint _amount) internal view returns(uint fee){
        fee = (_amount.mul(basisPointsRate)).div(1000);
        if (fee > maximumFee) fee = maximumFee;
        if (fee < minimumFee) fee = minimumFee;
    }
    
     
    function transferToContract(address _to, uint _value, bytes memory _data) internal returns (bool success) {
        require(_value > 0 && balances[msg.sender]>=_value);
        require(_to != msg.sender && _to != address(0));
        uint fee = calculateFee(_value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value.sub(fee));
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
        }
        ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value,  _data, fee);
        holderIsExist(_to);
        return true;
    }
    
     
    function transferToAddress(address _to, uint _value, bytes memory _data) internal returns (bool success) {
        require(_value > 0 && balances[msg.sender]>=_value);
        require(_to != msg.sender && _to != address(0));
        uint fee = calculateFee(_value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value.sub(fee));
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
        }
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value,  _data, fee);
        holderIsExist(_to);
        return true;
    }
    
     
    function holderIsExist(address _holder) internal returns (bool success){
        for(uint i=0;i<holders.length;i++)
            if(_holder==holders[i])
                success=true;
        if(!success) holders.push(_holder);
    }
    
     
    function holder() public onlyOwner view returns(address[] memory){
        return holders;
    }
}

 
contract Invcita is BasicERC223 {
    string public  name;
    string public symbol;
    uint8 public decimals;
    uint256 internal _totalSupply;
    bool public Auth;
    bool public deprecated;
    bytes empty;
   
     
    event Params(uint8 feeBasisPoints,uint maximumFee,uint minimumFee);
    
     
    modifier IsAuthenticate(){
        require(Auth);
        _;
    }
    
    constructor(string memory _name, string memory _symbol, uint256 totalSupply) public {
        name = _name;                                        
        symbol = _symbol;                                    
        decimals = 18;                                       
        _totalSupply = totalSupply * 10**uint(decimals);     
        balances[msg.sender] = _totalSupply;                 
        holders.push(msg.sender);
        emit Transfer(address(this),msg.sender,_totalSupply);
    }
    
     
    function totalSupply() IsAuthenticate public view returns (uint256) {
        return _totalSupply;
    }
    
     
    function balanceOf(address _owner) IsAuthenticate public view returns (uint balance) {
        return balances[_owner];
    }
    
     
    function transfer(address to, uint value) public IsAuthenticate returns (bool success) {
        require(!deprecated);
        require(!isBlackListed[msg.sender] && !isBlackListed[to]);
        if(isContract(to)) return transferToContract(to, value, empty);
        else return transferToAddress(to, value, empty);
    }
    
     
    function transfer(address to, uint value, bytes memory data) public IsAuthenticate returns (bool success) {
        require(!deprecated);
        require(!isBlackListed[msg.sender] && !isBlackListed[to]);
        if(isContract(to)) return transferToContract(to, value, data);
        else return transferToAddress(to, value, data);
    }
    
     
    function authenticate(address _authenticate) onlyOwner public returns(bool){
        return Auth = Authenticity(_authenticate).getAddress(address(this));
    }
    
     
    function withdrawForeignTokens(address _tokenContract) onlyOwner IsAuthenticate public returns (bool) {
        ERC223Interface token = ERC223Interface(_tokenContract);
        uint tokenBalance = token.balanceOf(address(this));
        return token.transfer(owner,tokenBalance);
    }
    
     
    function increaseSupply(uint amount) public onlyOwner IsAuthenticate{
        require(amount <= 10000000);
        amount = amount.mul(10**uint(decimals));
        balances[owner] = balances[owner].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), owner, amount);
    }
    
     
    function decreaseSupply(uint amount) public onlyOwner IsAuthenticate {
        require(amount <= 10000000);
        amount = amount.mul(10**uint(decimals));
        require(_totalSupply >= amount && balances[owner] >= amount);
        _totalSupply = _totalSupply.sub(amount);
        balances[owner] = balances[owner].sub(amount);
        emit Transfer(owner, address(0), amount);
    }
    
     
    function setParams(uint8 newBasisPoints, uint newMaxFee, uint newMinFee) public onlyOwner IsAuthenticate{
        require(newBasisPoints <= 9);
        require(newMaxFee >= 5 && newMaxFee <= 100);
        require(newMinFee <= 5);
        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(10**uint(decimals));
        minimumFee = newMinFee.mul(10**uint(decimals));
        emit Params(basisPointsRate, maximumFee, minimumFee);
    }
    
     
    function destroyBlackFunds(address _blackListedUser) public onlyOwner IsAuthenticate{
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balances[_blackListedUser];
        balances[_blackListedUser] = 0;
        _totalSupply = _totalSupply.sub(dirtyFunds);
        emit Transfer(_blackListedUser, address(0), dirtyFunds);
    }
    
     
    function deprecate(address _upgradedAddress) public onlyOwner IsAuthenticate returns (bool success){
        require(!deprecated);
        deprecated = true;
        UpgradedStandardToken upd = UpgradedStandardToken(_upgradedAddress);
        for(uint i=0; i<holders.length;i++){
            if(balances[holders[i]] > 0 && !isBlackListed[holders[i]]){
                upd.transferByHolder(holders[i],balances[holders[i]]);
                balances[holders[i]] = 0;
            }
        }
        return true;
    }
    
     
    function destroyContract(address payable _owner) public onlyOwner IsAuthenticate{
        require(_owner == owner);
        selfdestruct(_owner);
    }
}