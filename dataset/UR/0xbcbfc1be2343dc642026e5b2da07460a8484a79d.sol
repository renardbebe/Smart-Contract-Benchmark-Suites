 

pragma solidity ^0.4.15;

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

contract Ownable {

     
    address public owner;

    address public newOwner;

     
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function Ownable() public {
        owner = msg.sender;
    }

     

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract LamdenTau is MintableToken {
    string public constant name = "Lamden Tau";
    string public constant symbol = "TAU";
    uint8 public constant decimals = 18;
}

contract Bounty is Ownable {

   LamdenTau public lamdenTau;

   function Bounty(address _tokenContractAddress) public {
      require(_tokenContractAddress != address(0));
      lamdenTau = LamdenTau(_tokenContractAddress);
      
      
   }

   function returnTokens() onlyOwner {
      uint256 balance = lamdenTau.balanceOf(this);
      lamdenTau.transfer(msg.sender, balance);
   }

   function issueTokens() onlyOwner  {
      
    lamdenTau.transfer(0xC89A8574F18A8c0A8cde61de7E5b965451A53512, 250000000000000000000);
    lamdenTau.transfer(0x855382E202d3DCaDfda10f62969b38DcEe558270, 750000000000000000000);
    lamdenTau.transfer(0x5fAcAaDD40AE912Dccf963096BCb530c413839EE, 750000000000000000000);
    lamdenTau.transfer(0x85c40DB007BABA70d45559D259F8732E5909eBAB, 750000000000000000000);
    lamdenTau.transfer(0xa2ed565D1177360C41181E9F4dB17d6c0100fD5c, 250000000000000000000);
    lamdenTau.transfer(0xa2ed565D1177360C41181E9F4dB17d6c0100fD5c, 250000000000000000000);
    lamdenTau.transfer(0xcBa9A3AC842C203eAAA4C7Cb455CFf50cEe30581, 250000000000000000000);
    lamdenTau.transfer(0x87c90d805144e25672b314F2C7367a394AFf2F2B, 250000000000000000000);
    lamdenTau.transfer(0xD399E4f178D269DbdaD44948FdEE157Ca574E286, 500000000000000000000);
    lamdenTau.transfer(0x478A431b1644FdC254637d171Fa5663A739f8eF2, 500000000000000000000);
    lamdenTau.transfer(0x5F53C937FD1cc13c75B12Db84F61cbE58A4a255e, 250000000000000000000);
    lamdenTau.transfer(0x7fDf4D7a476934e348FC1C9efa912F3D7C07a80A, 250000000000000000000);
    lamdenTau.transfer(0xe47BBeAc8F268d7126082D5574B6f027f95AF5FB, 500000000000000000000);
    lamdenTau.transfer(0x5c582DE6968264f1865C63DD72f0904bE8e3dA4a, 250000000000000000000);
    lamdenTau.transfer(0x0c49d7f01E51FCC23FBFd175beDD6A571b29B27A, 250000000000000000000);
    lamdenTau.transfer(0x8ab7D4C2AA578D927F1FB8EF839001886731442E, 250000000000000000000);
    lamdenTau.transfer(0x58D0ba8C8aAD2c1946cf246B6F6455F80f645C8D, 250000000000000000000);
    lamdenTau.transfer(0xDb159732aEEBc8aB3E26fA19d2d144e4eACAAca2, 250000000000000000000);
    lamdenTau.transfer(0x7c3AeD95e0dC23E6Af5D58d108B9c18F44Da598C, 250000000000000000000);
    lamdenTau.transfer(0x9ca23235728ce9eF5bc879A9Abb68aF3a003551C, 250000000000000000000);
    lamdenTau.transfer(0xb81e0b4fcC4D54A2558214cb45da58b7a223C47C, 250000000000000000000);
    lamdenTau.transfer(0x58D0ba8C8aAD2c1946cf246B6F6455F80f645C8D, 250000000000000000000);
    lamdenTau.transfer(0xbDF7c509Db3bB8609730b3306E3C795173a4aEfc, 250000000000000000000);

      uint256 balance = lamdenTau.balanceOf(this);
      lamdenTau.transfer(msg.sender, balance);
   }

}