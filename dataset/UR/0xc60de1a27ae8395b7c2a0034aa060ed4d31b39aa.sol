 

pragma solidity >=0.4.23;

   

 
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

 
contract Contactable is Ownable {

  string public contactInformation;

   
  function setContactInformation(string info) onlyOwner public {
    contactInformation = info;
  }
}

contract LOCIcredits is Ownable, Contactable {    
    using SafeMath for uint256;    

    StandardToken token;  
    mapping (address => bool) internal allowedOverrideAddresses;

    mapping (string => LOCIuser) users;    
    string[] userKeys;
    uint256 userCount;        

     
    event UserAdded( string id, uint256 time );

     
    event CreditsAdjusted( string id, uint8 adjustment, uint256 value, uint8 reason, address register );    

     
    event CreditsTransferred( string id, uint256 value, uint8 reason, string beneficiary );

    modifier onlyOwnerOrOverride() {
         
         
        require(msg.sender == owner || allowedOverrideAddresses[msg.sender]);
        _;
    }

    struct LOCIuser {        
        uint256 credits;
        bool registered;
        address wallet;
    }
    
    constructor( address _token, string _contactInformation ) public {
        owner = msg.sender;
        token = StandardToken(_token);  
        contactInformation = _contactInformation;        
    }    
    
    function increaseCredits( string _id, uint256 _value, uint8 _reason, address _register ) public onlyOwnerOrOverride returns(uint256) {
                
        LOCIuser storage user = users[_id];

        if( !user.registered ) {
            user.registered = true;
            userKeys.push(_id);
            userCount = userCount.add(1);
            emit UserAdded(_id,now);
        }

        user.credits = user.credits.add(_value);        
        require( token.transferFrom( _register, address(this), _value ) );
        emit CreditsAdjusted(_id, 1, _value, _reason, _register);
        return user.credits;
    }

    function reduceCredits( string _id, uint256 _value, uint8 _reason, address _register ) public onlyOwnerOrOverride returns(uint256) {
             
        LOCIuser storage user = users[_id];     
        require( user.registered );
         
        user.credits = user.credits.sub(_value);        
        require( user.credits >= 0 );        
        require( token.transfer( _register, _value ) );           
        emit CreditsAdjusted(_id, 2, _value, _reason, _register);        
        
        return user.credits;
    }        

    function buyCreditsAndSpend( string _id, uint256 _value, uint8 _reason, address _register, uint256 _spend ) public onlyOwnerOrOverride returns(uint256) {
        increaseCredits(_id, _value, _reason, _register);
        return reduceCredits(_id, _spend, _reason, _register );        
    }        

    function buyCreditsAndSpendAndRecover(string _id, uint256 _value, uint8 _reason, address _register, uint256 _spend, address _recover ) public onlyOwnerOrOverride returns(uint256) {
        buyCreditsAndSpend(_id, _value, _reason, _register, _spend);
        return reduceCredits(_id, getCreditsFor(_id), _reason, _recover);
    }    

    function transferCreditsInternally( string _id, uint256 _value, uint8 _reason, string _beneficiary ) public onlyOwnerOrOverride returns(uint256) {        

        LOCIuser storage user = users[_id];   
        require( user.registered );

        LOCIuser storage beneficiary = users[_beneficiary];
        if( !beneficiary.registered ) {
            beneficiary.registered = true;
            userKeys.push(_beneficiary);
            userCount = userCount.add(1);
            emit UserAdded(_beneficiary,now);
        }

        require(_value <= user.credits);        
        user.credits = user.credits.sub(_value);
        require( user.credits >= 0 );
        
        beneficiary.credits = beneficiary.credits.add(_value);
        require( beneficiary.credits >= _value );

        emit CreditsAdjusted(_id, 2, _value, _reason, 0x0);
        emit CreditsAdjusted(_beneficiary, 1, _value, _reason, 0x0);
        emit CreditsTransferred(_id, _value, _reason, _beneficiary );
        
        return user.credits;
    }   

    function assignUserWallet( string _id, address _wallet ) public onlyOwnerOrOverride returns(uint256) {
        LOCIuser storage user = users[_id];   
        require( user.registered );
        user.wallet = _wallet;
        return user.credits;
    }

    function withdrawUserSpecifiedFunds( string _id, uint256 _value, uint8 _reason ) public returns(uint256) {
        LOCIuser storage user = users[_id];           
        require( user.registered, "user is not registered" );    
        require( user.wallet == msg.sender, "user.wallet is not msg.sender" );
        
        user.credits = user.credits.sub(_value);
        require( user.credits >= 0 );               
        require( token.transfer( user.wallet, _value ), "transfer failed" );                   
        emit CreditsAdjusted(_id, 2, _value, _reason, user.wallet );        
        
        return user.credits;
    }

    function getUserWallet( string _id ) public constant returns(address) {
        return users[_id].wallet;
    }

    function getTotalSupply() public constant returns(uint256) {        
        return token.balanceOf(address(this));
    }

    function getCreditsFor( string _id ) public constant returns(uint256) {
        return users[_id].credits;
    }

    function getUserCount() public constant returns(uint256) {
        return userCount;
    }    

    function getUserKey(uint256 _index) public constant returns(string) {
        require(_index <= userKeys.length-1);
        return userKeys[_index];
    }

    function getCreditsAtIndex(uint256 _index) public constant returns(uint256) {
        return getCreditsFor(getUserKey(_index));
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

         
        uint256 _amount = _value > 0 ? _value : address(this).balance;

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

     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return StandardToken(tokenAddress).transfer(owner, tokens);
    }
}