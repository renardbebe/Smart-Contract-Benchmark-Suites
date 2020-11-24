 

pragma solidity ^0.4.13;

contract ERC20Basic {

  function balanceOf(address who) public constant returns (uint256);

  function transfer(address to, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

}

contract ERC20 is ERC20Basic {

  function allowance(address owner, address spender) public constant returns (uint256);

  function transferFrom(address from, address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract ERC223 is ERC20 {



    function name() constant returns (string _name);

    function symbol() constant returns (string _symbol);

    function decimals() constant returns (uint8 _decimals);



    function transfer(address to, uint256 value, bytes data) returns (bool);



}

contract ERC223ReceivingContract {

    function tokenFallback(address _from, uint256 _value, bytes _data);

}

contract KnowledgeTokenInterface is ERC223{

    event Mint(address indexed to, uint256 amount);



    function changeMinter(address newAddress) returns (bool);

    function mint(address _to, uint256 _amount) returns (bool);

}

contract Ownable {

  address public owner;





  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);





   

  function Ownable() {

    owner = msg.sender;

  }





   

  modifier onlyOwner() {

    require(msg.sender == owner);

    _;

  }





   

  function transferOwnership(address newOwner) onlyOwner public {

    require(newOwner != address(0));

    OwnershipTransferred(owner, newOwner);

    owner = newOwner;

  }



}

library SafeMath {

  function mul(uint256 a, uint256 b) internal constant returns (uint256) {

    uint256 c = a * b;

    assert(a == 0 || c / a == b);

    return c;

  }



  function div(uint256 a, uint256 b) internal constant returns (uint256) {

     

    uint256 c = a / b;

     

    return c;

  }



  function sub(uint256 a, uint256 b) internal constant returns (uint256) {

    assert(b <= a);

    return a - b;

  }



  function add(uint256 a, uint256 b) internal constant returns (uint256) {

    uint256 c = a + b;

    assert(c >= a);

    return c;

  }

}

contract ERC20BasicToken is ERC20Basic {

  using SafeMath for uint256;



  mapping(address => uint256) balances;

  uint256 public totalSupply;



   

  function transfer(address _to, uint256 _value) public returns (bool) {

    require(_to != address(0));



     

    balances[msg.sender] = balances[msg.sender].sub(_value);

    balances[_to] = balances[_to].add(_value);

    Transfer(msg.sender, _to, _value);

    return true;

  }



   

  function balanceOf(address _owner) public constant returns (uint256 balance) {

    return balances[_owner];

  }



  function totalSupply() constant returns (uint256 _totalSupply) {

    return totalSupply;

  }



}

contract ERC20Token is ERC20, ERC20BasicToken {



  mapping (address => mapping (address => uint256)) allowed;



   

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

    require(_to != address(0));



    uint256 _allowance = allowed[_from][msg.sender];



     

     



    balances[_from] = balances[_from].sub(_value);

    balances[_to] = balances[_to].add(_value);

    allowed[_from][msg.sender] = _allowance.sub(_value);

    Transfer(_from, _to, _value);

    return true;

  }



   

  function approve(address _spender, uint256 _value) public returns (bool) {

    allowed[msg.sender][_spender] = _value;

    Approval(msg.sender, _spender, _value);

    return true;

  }



   

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {

    return allowed[_owner][_spender];

  }



   

  function increaseApproval (address _spender, uint _addedValue)

    returns (bool success) {

    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

    return true;

  }



  function decreaseApproval (address _spender, uint _subtractedValue)

    returns (bool success) {

    uint oldValue = allowed[msg.sender][_spender];

    if (_subtractedValue > oldValue) {

      allowed[msg.sender][_spender] = 0;

    } else {

      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);

    }

    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

    return true;

  }



}

contract ERC223Token is ERC223, ERC20Token {

    using SafeMath for uint256;



    string public name;



    string public symbol;



    uint8 public decimals;





     

    function name() constant returns (string _name) {

        return name;

    }

     

    function symbol() constant returns (string _symbol) {

        return symbol;

    }

     

    function decimals() constant returns (uint8 _decimals) {

        return decimals;

    }





     

    function transfer(address _to, uint256 _value, bytes _data) returns (bool success) {

        if (isContract(_to)) {

            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);

            receiver.tokenFallback(msg.sender, _value, _data);

        }

        return super.transfer(_to, _value);

    }



     

     

    function transfer(address _to, uint256 _value) returns (bool success) {

        if (isContract(_to)) {

            bytes memory empty;

            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);

            receiver.tokenFallback(msg.sender, _value, empty);

        }

        return super.transfer(_to, _value);

    }



     

    function isContract(address _addr) private returns (bool is_contract) {

        uint length;

        assembly {

            length := extcodesize(_addr)

        }

        return (length > 0);

    }



}

contract KnowledgeToken is KnowledgeTokenInterface, Ownable, ERC223Token {



    address public minter;



    modifier onlyMinter() {

         

        require (msg.sender == minter);

        _;

    }



    function mint(address _to, uint256 _amount) onlyMinter public returns (bool) {

        totalSupply = totalSupply.add(_amount);

        balances[_to] = balances[_to].add(_amount);

        Transfer(0x0, _to, _amount);

        Mint(_to, _amount);

        return true;

    }



    function changeMinter(address newAddress) public onlyOwner returns (bool)

    {

        minter = newAddress;

    }

}

contract WitCoin is KnowledgeToken{



    function WitCoin() {

        totalSupply = 0;

        name = "Witcoin";

        symbol = "WIT";

        decimals = 8;

    }



}