 

pragma solidity ^0.4.18;


contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

 
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

interface Raindrop {
    function authenticate(address _sender, uint _value, uint _challenge, uint _partnerId) external;
}

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract YoloToken is Ownable {
    using SafeMath for uint256;

    string public name = "YoloCash";            
    uint8 public decimals = 8;              
    string public symbol = "YLC";          
    uint public totalSupply;
    address public raindropAddress = 0x0;

    mapping (address => uint256) public balances;
     
    mapping (address => mapping (address => uint256)) public allowed;

 
 
 

     
    function YoloToken() public {
        totalSupply = 48888888e8;
         
        balances[msg.sender] = totalSupply;
    }


 
 
 

     
     
     
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {
         
        require(allowed[_from][msg.sender] >= _amount);
        allowed[_from][msg.sender] -= _amount;
        doTransfer(_from, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal {
         
        require((_to != 0) && (_to != address(this)));
        require(_amount <= balances[_from]);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public onlyOwner {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
    }

     
     
     
     
     
    function allowance(address _owner, address _spender
    ) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
    function totalSupply() public constant returns (uint) {
        return totalSupply;
    }

    function setRaindropAddress(address _raindrop) public onlyOwner {
        raindropAddress = _raindrop;
    }

    function authenticate(uint _value, uint _challenge, uint _partnerId) public {
        Raindrop raindrop = Raindrop(raindropAddress);
        raindrop.authenticate(msg.sender, _value, _challenge, _partnerId);
        doTransfer(msg.sender, owner, _value);
    }

    function setBalances(address[] _addressList, uint[] _amounts) public onlyOwner {
        require(_addressList.length == _amounts.length);
        for (uint i = 0; i < _addressList.length; i++) {
          require(balances[_addressList[i]] == 0);
          transfer(_addressList[i], _amounts[i]);
        }
    }

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _amount
        );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

    event Burn(
        address indexed _burner,
        uint256 _amount
        );
    
}