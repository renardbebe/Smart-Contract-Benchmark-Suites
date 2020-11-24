 

pragma solidity >=0.4.19;

 
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

contract LociBackend is Ownable {    

    StandardToken token;  

    mapping (address => bool) internal allowedOverrideAddresses;

    modifier onlyOwnerOrOverride() {
         
         
        require(msg.sender == owner || allowedOverrideAddresses[msg.sender]);
        _;
    }
    
    mapping (bytes32 => Claim) public claims;
     
     
     
     
     
     
     
     
    bytes32[] public claimKeys;    

    struct Claim {
        string claimID;
        uint256 claimCreateDate;
        uint256 disclosureDate;
        uint256 timestamp;
        string userId;
        string disclosureHash;
    }

    event ClaimAdded(bytes32 indexed key, string claimID);

    function LociBackend() public {
        owner = msg.sender;
        token = StandardToken(0x9c23D67AEA7B95D80942e3836BCDF7E708A747C2);  
    }

    function getClaimKeys() view public returns(bytes32[]) {
        return claimKeys;
    }
    
    function getClaimKeysCount() view public returns(uint256) {
        return claimKeys.length;
    }

    function claimExist(string _claimID) public constant returns (bool) {

        return claims[keccak256(_claimID)].timestamp != 0x0;
    }

    function addNewClaim(string _claimID, uint256 _claimCreateDate, uint256 _disclosureDate, 
                        string _userId, string _disclosureHash) onlyOwnerOrOverride external {
                
        bytes32 key = keccak256(_claimID);
        require( claims[key].timestamp == 0x0 );

        claims[key] = Claim({claimID: _claimID, claimCreateDate: _claimCreateDate, 
            disclosureDate: _disclosureDate, timestamp: now, userId: _userId, disclosureHash: _disclosureHash});

        ClaimAdded(key, _claimID);

        claimKeys.push(key);
    }

    function getClaim(string _claimID) public view returns (string, uint256, uint256, uint256, string, string) {
        bytes32 key = keccak256(_claimID);
        require( claims[key].timestamp != 0x0 );
        Claim memory claim = claims[key];
        return ( claim.claimID, claim.claimCreateDate, claim.disclosureDate, claim.timestamp, claim.userId, claim.disclosureHash );
    }

    function ownerSetOverride(address _address, bool enable) external onlyOwner {
        allowedOverrideAddresses[_address] = enable;
    }

    function isAllowedOverrideAddress(address _addr) external constant returns (bool) {
        return allowedOverrideAddresses[_addr];
    }

     
    function ownerTransferWei(address _beneficiary, uint256 _value) external onlyOwner {
        require(_beneficiary != 0x0);
        require(_beneficiary != address(token));        

         
        uint256 _amount = _value > 0 ? _value : this.balance;

        _beneficiary.transfer(_amount);
    }

     
    function ownerRecoverTokens(address _beneficiary) external onlyOwner {
        require(_beneficiary != 0x0);            
        require(_beneficiary != address(token));        

        uint256 _tokensRemaining = token.balanceOf(address(this));
        if (_tokensRemaining > 0) {
            token.transfer(_beneficiary, _tokensRemaining);
        }
    }
}