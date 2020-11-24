 

pragma solidity ^0.4.23;




 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}






 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}



 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(address _to, uint256 _amount) hasMintPermission canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


 
contract OptionsToken is StandardToken, Ownable {
    using SafeMath for uint256;
    bool revertable = true;
    mapping (address => uint256) public optionsOwner;
    
    modifier hasOptionPermision() {
        require(msg.sender == owner);
        _;
    }  

    function storeOptions(address recipient, uint256 amount) public hasOptionPermision() {
        optionsOwner[recipient] += amount;
    }

    function refundOptions(address discharged) public onlyOwner() returns (bool) {
        require(revertable);
        require(optionsOwner[discharged] > 0);
        require(optionsOwner[discharged] <= balances[discharged]);

        uint256 revertTokens = optionsOwner[discharged];
        optionsOwner[discharged] = 0;

        balances[discharged] = balances[discharged].sub(revertTokens);
        balances[owner] = balances[owner].add(revertTokens);
        emit Transfer(discharged, owner, revertTokens);
        return true;
    }

    function doneOptions() public onlyOwner() {
        require(revertable);
        revertable = false;
    }
}



 
contract ContractableToken is MintableToken, OptionsToken {
    address[5] public contract_addr;
    uint8 public contract_num = 0;

    function existsContract(address sender) public view returns(bool) {
        bool found = false;
        for (uint8 i = 0; i < contract_num; i++) {
            if (sender == contract_addr[i]) {
                found = true;
            }
        }
        return found;
    }

    modifier onlyContract() {
        require(existsContract(msg.sender));
        _;
    }

    modifier hasMintPermission() {
        require(existsContract(msg.sender));
        _;
    }
    
    modifier hasOptionPermision() {
        require(existsContract(msg.sender));
        _;
    }  
  
    event ContractRenounced();
    event ContractTransferred(address indexed newContract);
  
     
    function setContract(address newContract) public onlyOwner() {
        require(newContract != address(0));
        contract_num++;
        require(contract_num <= 5);
        emit ContractTransferred(newContract);
        contract_addr[contract_num-1] = newContract;
    }
  
    function renounceContract() public onlyOwner() {
        emit ContractRenounced();
        contract_num = 0;
    }
  
}



 
contract FTIToken is ContractableToken {

    string public constant name = "GlobalCarService Token";
    string public constant symbol = "FTI";
    uint8 public constant decimals = 18;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(msg.sender == owner || mintingFinished);
        super.transferFrom(_from, _to, _value);
        return true;
    }
  
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(msg.sender == owner || mintingFinished);
        super.transfer(_to, _value);
        return true;
    }
}