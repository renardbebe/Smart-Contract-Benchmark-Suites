 

pragma solidity ^0.4.24;

 

 
contract CloneFactory {

     
    address internal owner;
    
     
    event CloneCreated(address indexed target, address clone);

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
     
    constructor() public{
        owner = msg.sender;
    }    
    
     
    function setOwner(address _owner) public onlyOwner(){
        owner = _owner;
    }

     
    function createClone(address target) internal returns (address result) {
        bytes memory clone = hex"600034603b57603080600f833981f36000368180378080368173bebebebebebebebebebebebebebebebebebebebe5af43d82803e15602c573d90f35b3d90fd";
        bytes20 targetBytes = bytes20(target);
        for (uint i = 0; i < 20; i++) {
            clone[26 + i] = targetBytes[i];
        }
        assembly {
            let len := mload(clone)
            let data := add(clone, 0x20)
            result := create(0, data, len)
        }
    }
}

 

 
interface Factory_Interface {
  function createToken(uint _supply, address _party, uint _start_date) external returns (address,address, uint);
  function payToken(address _party, address _token_add) external;
  function deployContract(uint _start_date) external payable returns (address);
   function getBase() external view returns(address);
  function getVariables() external view returns (address, uint, uint, address,uint);
  function isWhitelisted(address _member) external view returns (bool);
}

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

  function min(uint a, uint b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

 

 
library DRCTLibrary{

    using SafeMath for uint256;

     
     
    struct Balance {
        address owner;
        uint amount;
        }

    struct TokenStorage{
         
        address factory_contract;
         
        uint total_supply;
         
        mapping(address => Balance[]) swap_balances;
         
        mapping(address => mapping(address => uint)) swap_balances_index;
         
        mapping(address => address[]) user_swaps;
         
        mapping(address => mapping(address => uint)) user_swaps_index;
         
        mapping(address => uint) user_total_balances;
         
        mapping(address => mapping(address => uint)) allowed;
    }   

     
     
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event CreateToken(address _from, uint _value);
    
     
     
    function startToken(TokenStorage storage self,address _factory) public {
        self.factory_contract = _factory;
    }

     
    function isWhitelisted(TokenStorage storage self,address _member) internal view returns(bool){
        Factory_Interface _factory = Factory_Interface(self.factory_contract);
        return _factory.isWhitelisted(_member);
    }

     
    function getFactoryAddress(TokenStorage storage self) external view returns(address){
        return self.factory_contract;
    }

     
    function createToken(TokenStorage storage self,uint _supply, address _owner, address _swap) public{
        require(msg.sender == self.factory_contract);
         
        self.total_supply = self.total_supply.add(_supply);
         
        self.user_total_balances[_owner] = self.user_total_balances[_owner].add(_supply);
         
        if (self.user_swaps[_owner].length == 0)
            self.user_swaps[_owner].push(address(0x0));
         
        self.user_swaps_index[_owner][_swap] = self.user_swaps[_owner].length;
         
        self.user_swaps[_owner].push(_swap);
         
        self.swap_balances[_swap].push(Balance({
            owner: 0,
            amount: 0
        }));
         
        self.swap_balances_index[_swap][_owner] = 1;
         
        self.swap_balances[_swap].push(Balance({
            owner: _owner,
            amount: _supply
        }));
        emit CreateToken(_owner,_supply);
    }

     
    function pay(TokenStorage storage self,address _party, address _swap) public{
        require(msg.sender == self.factory_contract);
        uint party_balance_index = self.swap_balances_index[_swap][_party];
        require(party_balance_index > 0);
        uint party_swap_balance = self.swap_balances[_swap][party_balance_index].amount;
         
        self.user_total_balances[_party] = self.user_total_balances[_party].sub(party_swap_balance);
         
        self.total_supply = self.total_supply.sub(party_swap_balance);
         
        self.swap_balances[_swap][party_balance_index].amount = 0;
    }

     
    function balanceOf(TokenStorage storage self,address _owner) public constant returns (uint balance) {
       return self.user_total_balances[_owner]; 
     }

     
    function totalSupply(TokenStorage storage self) public constant returns (uint _total_supply) {
       return self.total_supply;
    }

     
    function removeFromSwapBalances(TokenStorage storage self,address _remove, address _swap) internal {
        uint last_address_index = self.swap_balances[_swap].length.sub(1);
        address last_address = self.swap_balances[_swap][last_address_index].owner;
         
        if (last_address != _remove) {
            uint remove_index = self.swap_balances_index[_swap][_remove];
             
            self.swap_balances_index[_swap][last_address] = remove_index;
             
            self.swap_balances[_swap][remove_index] = self.swap_balances[_swap][last_address_index];
        }
         
        delete self.swap_balances_index[_swap][_remove];
         
        self.swap_balances[_swap].length = self.swap_balances[_swap].length.sub(1);
    }

     
    function transferHelper(TokenStorage storage self,address _from, address _to, uint _amount) internal {
         
        address[] memory from_swaps = self.user_swaps[_from];
         
        for (uint i = from_swaps.length.sub(1); i > 0; i--) {
             
            uint from_swap_user_index = self.swap_balances_index[from_swaps[i]][_from];
            Balance memory from_user_bal = self.swap_balances[from_swaps[i]][from_swap_user_index];
             
            if (_amount >= from_user_bal.amount) {
                _amount -= from_user_bal.amount;
                 
                self.user_swaps[_from].length = self.user_swaps[_from].length.sub(1);
                 
                delete self.user_swaps_index[_from][from_swaps[i]];
                 
                if (self.user_swaps_index[_to][from_swaps[i]] != 0) {
                     
                    uint to_balance_index = self.swap_balances_index[from_swaps[i]][_to];
                    assert(to_balance_index != 0);
                     
                    self.swap_balances[from_swaps[i]][to_balance_index].amount = self.swap_balances[from_swaps[i]][to_balance_index].amount.add(from_user_bal.amount);
                     
                    removeFromSwapBalances(self,_from, from_swaps[i]);
                } else {
                     
                    if (self.user_swaps[_to].length == 0){
                        self.user_swaps[_to].push(address(0x0));
                    }
                self.user_swaps_index[_to][from_swaps[i]] = self.user_swaps[_to].length;
                 
                self.user_swaps[_to].push(from_swaps[i]);
                 
                self.swap_balances[from_swaps[i]][from_swap_user_index].owner = _to;
                 
                self.swap_balances_index[from_swaps[i]][_to] = self.swap_balances_index[from_swaps[i]][_from];
                 
                delete self.swap_balances_index[from_swaps[i]][_from];
            }
             
            if (_amount == 0)
                break;
            } else {
                 
                uint to_swap_balance_index = self.swap_balances_index[from_swaps[i]][_to];
                 
                if (self.user_swaps_index[_to][from_swaps[i]] != 0) {
                     
                    self.swap_balances[from_swaps[i]][to_swap_balance_index].amount = self.swap_balances[from_swaps[i]][to_swap_balance_index].amount.add(_amount);
                } else {
                     
                    if (self.user_swaps[_to].length == 0){
                        self.user_swaps[_to].push(address(0x0));
                    }
                    self.user_swaps_index[_to][from_swaps[i]] = self.user_swaps[_to].length;
                     
                    self.user_swaps[_to].push(from_swaps[i]);
                     
                    self.swap_balances_index[from_swaps[i]][_to] = self.swap_balances[from_swaps[i]].length;
                     
                    self.swap_balances[from_swaps[i]].push(Balance({
                        owner: _to,
                        amount: _amount
                    }));
                }
                 
                self.swap_balances[from_swaps[i]][from_swap_user_index].amount = self.swap_balances[from_swaps[i]][from_swap_user_index].amount.sub(_amount);
                 
                break;
            }
        }
    }

     
    function transfer(TokenStorage storage self, address _to, uint _amount) public returns (bool) {
        require(isWhitelisted(self,_to));
        uint balance_owner = self.user_total_balances[msg.sender];
        if (
            _to == msg.sender ||
            _to == address(0) ||
            _amount == 0 ||
            balance_owner < _amount
        ) return false;
        transferHelper(self,msg.sender, _to, _amount);
        self.user_total_balances[msg.sender] = self.user_total_balances[msg.sender].sub(_amount);
        self.user_total_balances[_to] = self.user_total_balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
     
    function transferFrom(TokenStorage storage self, address _from, address _to, uint _amount) public returns (bool) {
        require(isWhitelisted(self,_to));
        uint balance_owner = self.user_total_balances[_from];
        uint sender_allowed = self.allowed[_from][msg.sender];
        if (
            _to == _from ||
            _to == address(0) ||
            _amount == 0 ||
            balance_owner < _amount ||
            sender_allowed < _amount
        ) return false;
        transferHelper(self,_from, _to, _amount);
        self.user_total_balances[_from] = self.user_total_balances[_from].sub(_amount);
        self.user_total_balances[_to] = self.user_total_balances[_to].add(_amount);
        self.allowed[_from][msg.sender] = self.allowed[_from][msg.sender].sub(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

     
    function approve(TokenStorage storage self, address _spender, uint _amount) public returns (bool) {
        self.allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function addressCount(TokenStorage storage self, address _swap) public constant returns (uint) { 
        return self.swap_balances[_swap].length; 
    }

     
    function getBalanceAndHolderByIndex(TokenStorage storage self, uint _ind, address _swap) public constant returns (uint, address) {
        return (self.swap_balances[_swap][_ind].amount, self.swap_balances[_swap][_ind].owner);
    }

     
    function getIndexByAddress(TokenStorage storage self, address _owner, address _swap) public constant returns (uint) {
        return self.swap_balances_index[_swap][_owner]; 
    }

     
    function allowance(TokenStorage storage self, address _owner, address _spender) public constant returns (uint) {
        return self.allowed[_owner][_spender]; 
    }
}

 

 
contract DRCT_Token {

    using DRCTLibrary for DRCTLibrary.TokenStorage;

     
    DRCTLibrary.TokenStorage public drct;

     
     
    constructor() public {
        drct.startToken(msg.sender);
    }

     
    function createToken(uint _supply, address _owner, address _swap) public{
        drct.createToken(_supply,_owner,_swap);
    }

     
    function getFactoryAddress() external view returns(address){
        return drct.getFactoryAddress();
    }

     
    function pay(address _party, address _swap) public{
        drct.pay(_party,_swap);
    }

     
    function balanceOf(address _owner) public constant returns (uint balance) {
       return drct.balanceOf(_owner);
     }

     
    function totalSupply() public constant returns (uint _total_supply) {
       return drct.totalSupply();
    }

     
    function transfer(address _to, uint _amount) public returns (bool) {
        return drct.transfer(_to,_amount);
    }

     
    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        return drct.transferFrom(_from,_to,_amount);
    }

     
    function approve(address _spender, uint _amount) public returns (bool) {
        return drct.approve(_spender,_amount);
    }

     
    function addressCount(address _swap) public constant returns (uint) { 
        return drct.addressCount(_swap); 
    }

     
    function getBalanceAndHolderByIndex(uint _ind, address _swap) public constant returns (uint, address) {
        return drct.getBalanceAndHolderByIndex(_ind,_swap);
    }

     
    function getIndexByAddress(address _owner, address _swap) public constant returns (uint) {
        return drct.getIndexByAddress(_owner,_swap); 
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint) {
        return drct.allowance(_owner,_spender); 
    }
}

 

 
interface Deployer_Interface {
  function newContract(address _party, address user_contract, uint _start_date) external payable returns (address);
}

 

interface Membership_Interface {
    function getMembershipType(address _member) external constant returns(uint);
}

 

 
interface Wrapped_Ether_Interface {
  function totalSupply() external constant returns (uint);
  function balanceOf(address _owner) external constant returns (uint);
  function transfer(address _to, uint _amount) external returns (bool);
  function transferFrom(address _from, address _to, uint _amount) external returns (bool);
  function approve(address _spender, uint _amount) external returns (bool);
  function allowance(address _owner, address _spender) external constant returns (uint);
  function withdraw(uint _value) external;
  function createToken() external;

}

 

 
contract Factory {
    using SafeMath for uint256;
    
     
     
     
    address public owner;
    address public oracle_address;
     
    address public user_contract;
     
    address internal deployer_address;
    Deployer_Interface internal deployer;
    address public token;
     
    uint public fee;
     
    uint public swapFee;
     
    uint public duration;
     
    uint public multiplier;
     
    uint public token_ratio;
     
    address[] public contracts;
    uint[] public startDates;
    address public memberContract;
    uint whitelistedTypes;
    mapping(address => uint) public created_contracts;
    mapping(address => uint) public token_dates;
    mapping(uint => address) public long_tokens;
    mapping(uint => address) public short_tokens;
    mapping(address => uint) public token_type;  

     
     
    event ContractCreation(address _sender, address _created);

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
     
     constructor(uint _memberTypes) public {
        owner = msg.sender;
        whitelistedTypes=_memberTypes;
    }

     
    function init(address _owner, uint _memberTypes) public{
        require(owner == address(0));
        owner = _owner;
        whitelistedTypes=_memberTypes;
    }

     
    function setMemberContract(address _memberContract) public onlyOwner() {
        memberContract = _memberContract;
    }


     
    function isWhitelisted(address _member) public view returns (bool){
        Membership_Interface Member = Membership_Interface(memberContract);
        return Member.getMembershipType(_member)>= whitelistedTypes;
    }
 
     
    function getTokens(uint _date) public view returns(address, address){
        return(long_tokens[_date],short_tokens[_date]);
    }

     
    function getTokenType(address _token) public view returns(uint){
        return(token_type[_token]);
    }

     
    function setFee(uint _fee) public onlyOwner() {
        fee = _fee;
    }

     
    function setSwapFee(uint _swapFee) public onlyOwner() {
        swapFee = _swapFee;
    }   

     
    function setDeployer(address _deployer) public onlyOwner() {
        deployer_address = _deployer;
        deployer = Deployer_Interface(_deployer);
    }

     
    function setUserContract(address _userContract) public onlyOwner() {
        user_contract = _userContract;
    }

     
    function setVariables(uint _token_ratio, uint _duration, uint _multiplier, uint _swapFee) public onlyOwner() {
        require(_swapFee < 10000);
        token_ratio = _token_ratio;
        duration = _duration;
        multiplier = _multiplier;
        swapFee = _swapFee;
    }

     
    function setBaseToken(address _token) public onlyOwner() {
        token = _token;
    }

     
    function deployContract(uint _start_date) public payable returns (address) {
        require(msg.value >= fee && isWhitelisted(msg.sender));
        require(_start_date % 86400 == 0);
        address new_contract = deployer.newContract(msg.sender, user_contract, _start_date);
        contracts.push(new_contract);
        created_contracts[new_contract] = _start_date;
        emit ContractCreation(msg.sender,new_contract);
        return new_contract;
    }

     
    function deployTokenContract(uint _start_date) public{
        address _token;
        require(_start_date % 86400 == 0);
        require(long_tokens[_start_date] == address(0) && short_tokens[_start_date] == address(0));
        _token = new DRCT_Token();
        token_dates[_token] = _start_date;
        long_tokens[_start_date] = _token;
        token_type[_token]=2;
        _token = new DRCT_Token();
        token_type[_token]=1;
        short_tokens[_start_date] = _token;
        token_dates[_token] = _start_date;
        startDates.push(_start_date);

    }

     
    function createToken(uint _supply, address _party, uint _start_date) public returns (address, address, uint) {
        require(created_contracts[msg.sender] == _start_date);
        address ltoken = long_tokens[_start_date];
        address stoken = short_tokens[_start_date];
        require(ltoken != address(0) && stoken != address(0));
            DRCT_Token drct_interface = DRCT_Token(ltoken);
            drct_interface.createToken(_supply.div(token_ratio), _party,msg.sender);
            drct_interface = DRCT_Token(stoken);
            drct_interface.createToken(_supply.div(token_ratio), _party,msg.sender);
        return (ltoken, stoken, token_ratio);
    }
  
     
    function setOracleAddress(address _new_oracle_address) public onlyOwner() {
        oracle_address = _new_oracle_address; 
    }

     
    function setOwner(address _new_owner) public onlyOwner() { 
        owner = _new_owner; 
    }

     
    function withdrawFees() public onlyOwner(){
        Wrapped_Ether_Interface token_interface = Wrapped_Ether_Interface(token);
        uint _val = token_interface.balanceOf(address(this));
        if(_val > 0){
            token_interface.withdraw(_val);
        }
        owner.transfer(address(this).balance);
     }

      
    function() public payable {
    }

     
    function getVariables() public view returns (address, uint, uint, address,uint){
        return (oracle_address,duration, multiplier, token,swapFee);
    }

     
    function payToken(address _party, address _token_add) public {
        require(created_contracts[msg.sender] > 0);
        DRCT_Token drct_interface = DRCT_Token(_token_add);
        drct_interface.pay(_party, msg.sender);
    }

     
    function getCount() public constant returns(uint) {
        return contracts.length;
    }

     
    function getDateCount() public constant returns(uint) {
        return startDates.length;
    }
}

 

 

contract MasterDeployer is CloneFactory{
    
    using SafeMath for uint256;

     
	address[] factory_contracts;
	address private factory;
	mapping(address => uint) public factory_index;

     
	event NewFactory(address _factory);

     
     
	constructor() public {
		factory_contracts.push(address(0));
	}

     	
	function setFactory(address _factory) public onlyOwner(){
		factory = _factory;
	}

     
	function deployFactory(uint _memberTypes) public onlyOwner() returns(address){
		address _new_fac = createClone(factory);
		factory_index[_new_fac] = factory_contracts.length;
		factory_contracts.push(_new_fac);
		Factory(_new_fac).init(msg.sender,_memberTypes);
		emit NewFactory(_new_fac);
		return _new_fac;
	}

     
	function removeFactory(address _factory) public onlyOwner(){
		require(_factory != address(0) && factory_index[_factory] != 0);
		uint256 fIndex = factory_index[_factory];
        uint256 lastFactoryIndex = factory_contracts.length.sub(1);
        address lastFactory = factory_contracts[lastFactoryIndex];
        factory_contracts[fIndex] = lastFactory;
        factory_index[lastFactory] = fIndex;
        factory_contracts.length--;
        factory_index[_factory] = 0;
	}

     
	function getFactoryCount() public constant returns(uint){
		return factory_contracts.length - 1;
	}

     
	function getFactorybyIndex(uint _index) public constant returns(address){
		return factory_contracts[_index];
	}
}