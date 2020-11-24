 

pragma solidity ^0.4.18;

 

 
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
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  using SafeMath for uint256;
  uint256 public startdate;

  function Ownable() public {

    owner = msg.sender;
    startdate = now;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }


}

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  mapping(address => uint256) private _lock_list_period;
  mapping(address => bool) private _lock_list;
  bool public paused = false;
  mapping(address => uint256) internal _balances;
  uint256 internal _tokenSupply;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }
   



  modifier isLockAddress() {
    check_lock_period(msg.sender);
    if(_lock_list[msg.sender]){
        revert();
    }

    _;

  }

  function check_lock_period(address check_address) {
      if(now > _lock_list_period[check_address] && _lock_list[check_address]){
        _lock_list[check_address] = false;
        _tokenSupply = _tokenSupply.add(_balances[check_address]);
      }

  }

  function check_period(address check_address) constant public returns(uint256){
      return _lock_list_period[check_address];

  }

  function check_lock(address check_address) constant public returns(bool){

      return _lock_list[check_address];

  }
   
  function set_lock_list(address lock_address, uint period) onlyOwner external {
      _lock_list_period[lock_address] = startdate + (period * 1 days);
      _lock_list[lock_address]  = true;
      _tokenSupply = _tokenSupply.sub(_balances[lock_address]);
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }
   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 

 

interface ERC20Token {

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 

interface ERC223 {

    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public returns (bool);

}

 

 

 contract ContractReceiver {

    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }


    function tokenFallback(address _from, uint _value, bytes _data) public pure {
      TKN memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      tkn.sig = bytes4(u);

       
    }
}

 

 

contract Veen is ERC20Token, Pausable, ERC223{

    using SafeMath for uint;

    string public constant name = "Veen";
    string public constant symbol = "VEEN";
    uint8 public constant decimals = 18;

    uint private _totalSupply;

    mapping(address => mapping(address => uint256)) private _allowed;
    event MintedLog(address to, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint value);


    function Veen() public {
        _tokenSupply = 0;
        _totalSupply = 15000000000 * (uint256(10) ** decimals);

    }

    function totalSupply() public constant returns (uint256) {
        return _tokenSupply;
    }

    function mint(address to, uint256 amount) onlyOwner public returns (bool){

        amount = amount * (uint256(10) ** decimals);
        if(_totalSupply + 1 > (_tokenSupply+amount)){
            _tokenSupply = _tokenSupply.add(amount);
            _balances[to]= _balances[to].add(amount);
            emit MintedLog(to, amount);
            return true;
        }

        return false;
    }

    function dist_list_set(address[] dist_list, uint256[] token_list) onlyOwner external{

        for(uint i=0; i < dist_list.length ;i++){
            transfer(dist_list[i],token_list[i]);
        }

    }
    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return _balances[tokenOwner];
    }

    function transfer(address to, uint tokens) whenNotPaused isLockAddress public returns(bool success){
    bytes memory empty;
    	if(isContract(to)) {
        	return transferToContract(to, tokens, empty);
    	}
    	else {
        	return transferToAddress(to, tokens, empty);
    	}
    }


    function approve(address spender, uint256 tokens) public returns (bool success) {

        if (tokens > 0 && balanceOf(msg.sender) >= tokens) {
            _allowed[msg.sender][spender] = tokens;
            emit Approval(msg.sender, spender, tokens);
            return true;
        }

        return false;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return _allowed[tokenOwner][spender];
    }

    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        if (tokens > 0 && balanceOf(from) >= tokens && _allowed[from][msg.sender] >= tokens) {
            _balances[from] = _balances[from].sub(tokens);
            _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(tokens);
            _balances[to] = _balances[to].add(tokens);
            emit Transfer(msg.sender, to, tokens);
            return true;
        }
        return false;
    }

    function burn(uint256 tokens) public returns (bool success) {
        if ( tokens > 0 && balanceOf(msg.sender) >= tokens ) {
            _balances[msg.sender] = _balances[msg.sender].sub(tokens);
            _tokenSupply = _tokenSupply.sub(tokens);
            return true;
        }

        return false;
    }
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    _balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    _balances[_to] = balanceOf(_to).add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    _balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    _balances[_to] = balanceOf(_to).add(_value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    emit Transfer(msg.sender, _to, _value);
    return true;
}



    function isContract(address _addr) view returns (bool is_contract){
      uint length;
      assembly {
            length := extcodesize(_addr)
      }
      return (length>0);
    }

    function () public payable {
        throw;

    }
}