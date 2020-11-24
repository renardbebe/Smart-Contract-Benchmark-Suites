 

pragma solidity ^0.4.11;

 
 
 
 
 

contract Owned {

    address public owner;
    address public newOwner;

    event OwnershipTransferProposed(
      address indexed _from,
      address indexed _to
    );

    event OwnershipTransferred(
      address indexed _from,
      address indexed _to
    );

    function Owned()
    {
      owner = msg.sender;
    }

    modifier onlyOwner
    {
      require(msg.sender == owner);
      _;
    }

    function transferOwnership(address _newOwner) onlyOwner
    {
      require(_newOwner != address(0x0));
      OwnershipTransferProposed(owner, _newOwner);
      newOwner = _newOwner;
    }

    function acceptOwnership()
    {
      require(msg.sender == newOwner);
      OwnershipTransferred(owner, newOwner);
      owner = newOwner;
    }

}


 
 
 
 
 

contract SafeMath {

  function safeAdd(uint a, uint b) internal
    returns (uint)
  {
    uint c = a + b;
    assert(c >= a && c >= b);
    return c;
  }

  function safeSub(uint a, uint b) internal
    returns (uint)
  {
    assert(b <= a);
    uint c = a - b;
    assert(c <= a);
    return c;
  }

}


 
 
 
 
 
 

contract ERC20Interface {

    event LogTransfer(
      address indexed _from,
      address indexed _to,
      uint256 _value
    );
    
    event LogApproval(
      address indexed _owner,
      address indexed _spender,
      uint256 _value
    );

    function totalSupply() constant
      returns (uint256);
    
    function balanceOf(address _owner) constant 
      returns (uint256 balance);
    
    function transfer(address _to, uint256 _value)
      returns (bool success);
    
    function transferFrom(address _from, address _to, uint256 _value) 
      returns (bool success);
    
    function approve(address _spender, uint256 _value) 
      returns (bool success);
    
    function allowance(address _owner, address _spender) constant 
      returns (uint256 remaining);

}

 
 
 
 
 
 
 

contract ERC20Token is ERC20Interface, Owned, SafeMath {

     
     
    mapping(address => uint256) balances;

     
     
    mapping(address => mapping (address => uint256)) allowed;

     
    function balanceOf(address _owner) constant 
      returns (uint256 balance)
    {
      return balances[_owner];
    }

     
     
     
    function transfer(address _to, uint256 _amount) 
      returns (bool success)
    {
      require( _amount > 0 );                               
      require( balances[msg.sender] >= _amount );           
      require( balances[_to] + _amount > balances[_to] );   

      balances[msg.sender] -= _amount;
      balances[_to] += _amount;
      LogTransfer(msg.sender, _to, _amount);
      return true;
    }

     
     
     
     
     
    function approve(address _spender, uint256 _amount) 
      returns (bool success)
    {
       
       
       
      require( _amount == 0 || allowed[msg.sender][_spender] == 0 );
        
       
      require (balances[msg.sender] >= _amount);
        
      allowed[msg.sender][_spender] = _amount;
      LogApproval(msg.sender, _spender, _amount);
      return true;
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) 
    returns (bool success) 
    {
      require( _amount > 0 );                               
      require( balances[_from] >= _amount );                
      require( allowed[_from][msg.sender] >= _amount );     
      require( balances[_to] + _amount > balances[_to] );   

      balances[_from] -= _amount;
      allowed[_from][msg.sender] -= _amount;
      balances[_to] += _amount;
      LogTransfer(_from, _to, _amount);
      return true;
    }

     
     
     
     

    function allowance(address _owner, address _spender) constant 
    returns (uint256 remaining)
    {
      return allowed[_owner][_spender];
    }

}

 
 
 
 
 

contract Zorro02Token is ERC20Token {


     


     

    string public constant name = "Zorro02";
    string public constant symbol = "ZORRO02";
    uint8 public constant decimals = 18;
    string public constant GITHUB_LINK = 'htp: 

     
    
    address public wallet;

     

    uint public tokensPerEth = 100000;
    uint public icoTokenSupply = 300;

     

    uint public constant TOTAL_TOKEN_SUPPLY = 1000;
    uint public constant ICO_TRIGGER = 10;
    uint public constant MIN_CONTRIBUTION = 10**15;
    
     

     
     
     
    uint public constant START_DATE = 1502787600;
    uint public constant END_DATE = 1502791200;

     

    uint public icoTokensIssued = 0;
    bool public icoFinished = false;
    bool public tradeable = false;

     
    
    uint public ownerTokensMinted = 0;
    
     
    
    uint256 constant MULT_FACTOR = 10**18;
    

     

    
    event LogWalletUpdated(
      address newWallet
    );
    
    event LogTokensPerEthUpdated(
      uint newTokensPerEth
    );
    
    event LogIcoTokenSupplyUpdated(
      uint newIcoTokenSupply
    );
    
    event LogTokensBought(
      address indexed buyer,
      uint ethers,
      uint tokens, 
      uint participantTokenBalance, 
      uint newIcoTokensIssued
    );
    
    event LogMinting(
      address indexed participant,
      uint tokens,
      uint newOwnerTokensMinted
    );


     
    
     
     
     

    function Zorro02Token() {
      owner = msg.sender;
      wallet = msg.sender;
    }


     
     
     
    
    function totalSupply() constant
      returns (uint256)
    {
      return TOTAL_TOKEN_SUPPLY;
    }


     
     
     
    
     
     
    function setWallet(address _wallet) onlyOwner
    {
      wallet = _wallet;
      LogWalletUpdated(wallet);
    }
    
     
     
    function setTokensPerEth(uint _tokensPerEth) onlyOwner
    {
      require(now < START_DATE);
      require(_tokensPerEth > 0);
      tokensPerEth = _tokensPerEth;
      LogTokensPerEthUpdated(tokensPerEth);
    }
        

     
     
     
    function setIcoTokenSupply(uint _icoTokenSupply) onlyOwner
    {
        require(now < START_DATE);
        require(_icoTokenSupply < TOTAL_TOKEN_SUPPLY);
        icoTokenSupply = _icoTokenSupply;
        LogIcoTokenSupplyUpdated(icoTokenSupply);
    }


     
     
     
    
    function () payable
    {
        proxyPayment(msg.sender);
    }

     
     
     

    function proxyPayment(address participant) payable
    {
        require(!icoFinished);
        require(now >= START_DATE);
        require(now <= END_DATE);
        require(msg.value > MIN_CONTRIBUTION);
        
         
        uint tokens = msg.value * tokensPerEth;
        
         
        uint available = icoTokenSupply - icoTokensIssued;
        require (tokens <= available); 

         
        
         
         
        balances[participant] += tokens;
        icoTokensIssued += tokens;

         
        LogTransfer(0x0, participant, tokens);
        
         
        LogTokensBought(participant, msg.value, tokens, balances[participant], icoTokensIssued);

         
         
        wallet.transfer(msg.value);
    }

    
     
     
     

     
     
    function availableToMint()
      returns (uint)
    {
      if (icoFinished) {
        return TOTAL_TOKEN_SUPPLY - icoTokensIssued - ownerTokensMinted;
      } else {
        return TOTAL_TOKEN_SUPPLY - icoTokenSupply - ownerTokensMinted;        
      }
    }

     
     
    function mint(address participant, uint256 tokens) onlyOwner 
    {
        require( tokens <= availableToMint() );
        balances[participant] += tokens;
        ownerTokensMinted += tokens;
        LogTransfer(0x0, participant, tokens);
        LogMinting(participant, tokens, ownerTokensMinted);
    }

     
     
     
    
    function declareIcoFinished() onlyOwner
    {
       
      require( now > END_DATE || icoTokenSupply - icoTokensIssued < ICO_TRIGGER );
      icoFinished = true;
    }

     
     
     
    
    function tradeable() onlyOwner
    {
       
      require(icoFinished);
      tradeable = true;
    }

     
     
     

    function transfer(address _to, uint _amount) 
      returns (bool success)
    {
       
      require(tradeable || msg.sender == owner);
      return super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint _amount) 
      returns (bool success)
    {
         
        require(tradeable);
        return super.transferFrom(_from, _to, _amount);
    }

     
     
     

     
    function transferAnyERC20Token(address tokenAddress, uint amount) onlyOwner 
      returns (bool success) 
    {
        return ERC20Interface(tokenAddress).transfer(owner, amount);
    }

}