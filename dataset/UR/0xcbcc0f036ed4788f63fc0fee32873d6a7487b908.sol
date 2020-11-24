 

pragma solidity ^0.4.6;


 
contract SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


 
 
contract AbstractToken {
     
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}


contract StandardToken is AbstractToken {

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}


 
 
 
contract HumaniqToken is StandardToken, SafeMath {

     
    address public minter;

     
    string constant public name = "Humaniq";
    string constant public symbol = "HMQ";
    uint8 constant public decimals = 8;

     
    address public founder = 0xc890b1f532e674977dfdb791cafaee898dfa9671;

     
    address public multisig = 0xa2c9a7578e2172f32a36c5c0e49d64776f9e7883;

     
    address constant public allocationAddressICO = 0x1111111111111111111111111111111111111111;

     
    address constant public allocationAddressPreICO = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

     
    uint constant public preICOSupply = mul(31820314, 100000000);

     
    uint constant public ICOSupply = mul(131038286, 100000000);

     
    uint public maxTotalSupply;

     
    modifier onlyFounder() {
         
        if (msg.sender != founder) {
            throw;
        }
        _;
    }

    modifier onlyMinter() {
         
        if (msg.sender != minter) {
            throw;
        }
        _;
    }

     

     
     
     
    function issueTokens(address _for, uint tokenCount)
        external
        payable
        onlyMinter
        returns (bool)
    {
        if (tokenCount == 0) {
            return false;
        }

        if (add(totalSupply, tokenCount) > maxTotalSupply) {
            throw;
        }

        totalSupply = add(totalSupply, tokenCount);
        balances[_for] = add(balances[_for], tokenCount);
        Issuance(_for, tokenCount);
        return true;
    }

     
     
    function changeMinter(address newAddress)
        public
        onlyFounder
        returns (bool)
    {   
         
        delete allowed[allocationAddressICO][minter];

        minter = newAddress;

         
        allowed[allocationAddressICO][minter] = balanceOf(allocationAddressICO);
    }

     
     
    function changeFounder(address newAddress)
        public
        onlyFounder
        returns (bool)
    {   
        founder = newAddress;
    }

     
     
    function changeMultisig(address newAddress)
        public
        onlyFounder
        returns (bool)
    {
        multisig = newAddress;
    }

     
    function HumaniqToken(address founderAddress)
    {   
         
        founder = founderAddress;

         
        balances[allocationAddressICO] = ICOSupply;

         
        balances[allocationAddressPreICO] = preICOSupply;

         
        allowed[allocationAddressPreICO][founder] = preICOSupply;

         
        balances[multisig] = div(mul(ICOSupply, 14), 86);

         
        totalSupply = add(ICOSupply, balances[multisig]);
        totalSupply = add(totalSupply, preICOSupply);
        maxTotalSupply = mul(totalSupply, 5);
    }
}