 

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

  function cei(uint256 a, uint256 b) internal pure returns (uint256) {
    return ((a + b - 1) / b) * b;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool) {
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

 
contract Ownable {
  address public owner;                                                      
  address public masterOwner = 0x5D1EC7558C8D1c40406913ab5dbC0Abf1C96BA42;   

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public {
    require(newOwner != address(0));
    require(masterOwner == msg.sender);  
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract FTXToken is StandardToken, Ownable {

     
    string public constant name = "FintruX Network";
    string public constant symbol = "FTX";
    string public constant version = "1.0";
    uint8 public constant decimals = 18;

     
    uint256 public constant INITIAL_SUPPLY = 100000000 * 10**18;
    uint256 public constant FINTRUX_RESERVE_FTX = 10000000 * 10**18;
    uint256 public constant CROSS_RESERVE_FTX = 5000000 * 10**18;
    uint256 public constant TEAM_RESERVE_FTX = 10000000 * 10**18;

     
    address public constant FINTRUX_RESERVE = 0x633348b01B3f59c8A445365FB2ede865ecc94a0B;
    address public constant CROSS_RESERVE = 0xED200B7BC7044290c99993341a82a21c4c7725DB;
    address public constant TEAM_RESERVE = 0xfc0Dd77c6bd889819E322FB72D4a86776b1632d5;

     
    uint256 public constant VESTING_DATE = 1519837200 + 1 years;

     
    uint256 public token4Gas = 1*10**18;
     
    uint256 public gas4Token = 80000*0.6*10**9;
     
    uint256 public minGas4Accts = 80000*4*10**9;

    bool public allowTransfers = false;
    mapping (address => bool) public transferException;

    event Withdraw(address indexed from, address indexed to, uint256 value);
    event GasRebateFailed(address indexed to, uint256 value);

     
    function FTXToken() public {
        owner = msg.sender;
        totalSupply = INITIAL_SUPPLY;
        balances[owner] = INITIAL_SUPPLY - FINTRUX_RESERVE_FTX - CROSS_RESERVE_FTX - TEAM_RESERVE_FTX;
        Transfer(address(0), owner, balances[owner]);
        balances[FINTRUX_RESERVE] = FINTRUX_RESERVE_FTX;
        Transfer(address(0), FINTRUX_RESERVE, balances[FINTRUX_RESERVE]);
        balances[CROSS_RESERVE] = CROSS_RESERVE_FTX;
        Transfer(address(0), CROSS_RESERVE, balances[CROSS_RESERVE]);
        balances[TEAM_RESERVE] = TEAM_RESERVE_FTX;
        Transfer(address(0), TEAM_RESERVE, balances[TEAM_RESERVE]);
        transferException[owner] = true;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(canTransferTokens());                                                
        require(_value > 0 && _value >= token4Gas);                                  
        balances[msg.sender] = balances[msg.sender].sub(_value);                     
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
         
        if (this.balance > gas4Token && msg.sender.balance < minGas4Accts) {
             
            if (!msg.sender.send(gas4Token)) {
                GasRebateFailed(msg.sender,gas4Token);
            }
        }
        return true;
    }
    
     
    function setToken4Gas(uint256 newFTXAmount) public onlyOwner {
        require(newFTXAmount > 0);                                                   
        token4Gas = newFTXAmount;
    }

     
    function setGas4Token(uint256 newGasInWei) public onlyOwner {
        require(newGasInWei > 0 && newGasInWei <= 840000*10**9);             
        gas4Token = newGasInWei;
    }

     
    function setMinGas4Accts(uint256 minBalanceInWei) public onlyOwner {
        require(minBalanceInWei > 0 && minBalanceInWei <= 840000*10**9);     
        minGas4Accts = minBalanceInWei;
    }

     
    function() payable public onlyOwner {
    }

     
    function withdrawToOwner (uint256 weiAmt) public onlyOwner {
        require(weiAmt > 0);                                                 
        msg.sender.transfer(weiAmt);
        Withdraw(this, msg.sender, weiAmt);                                  
    }

     
    function setAllowTransfers(bool bAllowTransfers) external onlyOwner {
        allowTransfers = bAllowTransfers;
    }

     
    function addToException(address addr) external onlyOwner {
        require(addr != address(0));
        require(!isException(addr));

        transferException[addr] = true;
    }

     
    function delFrException(address addr) external onlyOwner {
        require(addr != address(0));
        require(transferException[addr]);

        delete transferException[addr];
    }

     
    function isException(address addr) public view returns (bool) {
        return transferException[addr];
    }

     
     
    function canTransferTokens() internal view returns (bool) {
        if (msg.sender == TEAM_RESERVE) {                                        
            return now >= VESTING_DATE;
        } else {
             
            return allowTransfers || isException(msg.sender);
        }
    }

}