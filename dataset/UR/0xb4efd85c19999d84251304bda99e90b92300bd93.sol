 

pragma solidity ^0.4.11;

contract Owned {

    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

contract SalesAgentInterface {
      
     
    address tokenContractAddress;
     
    mapping (address => uint256) public contributions;    
     
    uint256 public contributedTotal;                       
     
    modifier onlyTokenContract() {_;}
     
    event Contribute(address _agent, address _sender, uint256 _value);
    event FinaliseSale(address _agent, address _sender, uint256 _value);
    event Refund(address _agent, address _sender, uint256 _value);
    event ClaimTokens(address _agent, address _sender, uint256 _value);  
     
     
    function getDepositAddressVerify() public;
     
     
    function getContributionOf(address _owner) constant returns (uint256 balance);
}

 
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
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

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

 
 

 

contract RocketPoolToken is StandardToken, Owned {

      

    string public name = "Rocket Pool";
    string public symbol = "RPL";
    string public version = "1.0";
     
    uint8 public constant decimals = 18;
    uint256 public exponent = 10**uint256(decimals);
    uint256 public totalSupply = 0;                              
    uint256 public totalSupplyCap = 18 * (10**6) * exponent;     


     
    
    using SafeMath for uint;                           
    
    
     
       
    mapping (address => SalesAgent) private salesAgents;    
    address[] private salesAgentsAddresses;                 

     
             
    struct SalesAgent {                      
        address saleContractAddress;         
        bytes32 saleContractType;            
        uint256 targetEthMax;                
        uint256 targetEthMin;                
        uint256 tokensLimit;                 
        uint256 tokensMinted;                
        uint256 minDeposit;                  
        uint256 maxDeposit;                  
        uint256 startBlock;                  
        uint256 endBlock;                    
        address depositAddress;              
        bool depositAddressCheckedIn;        
        bool finalised;                      
        bool exists;                         
    }

     

    event MintToken(address _agent, address _address, uint256 _value);
    event SaleFinalised(address _agent, address _address, uint256 _value);
  
     

    event FlagUint(uint256 flag);
    event FlagAddress(address flag);

    
     

     
    modifier isSalesContract(address _sender) {
         
        assert(salesAgents[_sender].exists == true);
        _;
    }

    
     

     
    function RocketPoolToken() {}


     
     
     
    function validateContribution(uint256 _value) isSalesContract(msg.sender) returns (bool) {
         
        SalesAgentInterface saleAgent = SalesAgentInterface(msg.sender);
         
        assert(_value > 0);  
         
        assert(salesAgents[msg.sender].depositAddressCheckedIn == true);
         
        assert(block.number > salesAgents[msg.sender].startBlock);       
         
        assert(block.number < salesAgents[msg.sender].endBlock || salesAgents[msg.sender].endBlock == 0); 
         
        assert(_value >= salesAgents[msg.sender].minDeposit); 
         
        assert(_value <= salesAgents[msg.sender].maxDeposit); 
         
        assert(salesAgents[msg.sender].finalised == false);      
         
        assert(saleAgent.contributedTotal().add(_value) <= salesAgents[msg.sender].targetEthMax);       
         
        return true;
    }


     
     
     
    function validateClaimTokens(address _sender) isSalesContract(msg.sender) returns (bool) {
         
        SalesAgentInterface saleAgent = SalesAgentInterface(msg.sender);
         
        assert(saleAgent.getContributionOf(_sender) > 0); 
         
        assert(block.number > salesAgents[msg.sender].endBlock);  
         
        return true;
    }
    

     
     
     
     
    function mint(address _to, uint _amount) isSalesContract(msg.sender) returns (bool) {
         
         
        assert(block.number > salesAgents[msg.sender].startBlock);   
         
        assert(salesAgents[msg.sender].depositAddressCheckedIn == true);
         
        assert(salesAgents[msg.sender].finalised == false);
         
        assert(salesAgents[msg.sender].tokensLimit >= salesAgents[msg.sender].tokensMinted.add(_amount));
         
        assert(_amount > 0);
          
        assert(totalSupply.add(_amount) <= totalSupplyCap);
          
        balances[_to] = balances[_to].add(_amount);
         
        salesAgents[msg.sender].tokensMinted = salesAgents[msg.sender].tokensMinted.add(_amount);
         
        totalSupply = totalSupply.add(_amount);
         
        MintToken(msg.sender, _to, _amount);
         
        Transfer(0x0, _to, _amount); 
         
        return true; 
    }

     
    function getRemainingTokens() public constant returns(uint256) {
        return totalSupplyCap.sub(totalSupply);
    }
    
     
     
     
     
     
     
     
     
     
     
     
    function setSaleAgentContract(
        address _saleAddress, 
         string _saleContractType, 
        uint256 _targetEthMin, 
        uint256 _targetEthMax, 
        uint256 _tokensLimit, 
        uint256 _minDeposit,
        uint256 _maxDeposit,
        uint256 _startBlock, 
        uint256 _endBlock, 
        address _depositAddress
    ) 
     
    public onlyOwner  
    {
         
        assert(_saleAddress != 0x0 && _depositAddress != 0x0);  
         
        assert(_tokensLimit > 0 && _tokensLimit <= totalSupplyCap);
         
        assert(_minDeposit <= _maxDeposit);
         
        salesAgents[_saleAddress] = SalesAgent({
            saleContractAddress: _saleAddress,
            saleContractType: sha3(_saleContractType),
            targetEthMin: _targetEthMin,
            targetEthMax: _targetEthMax,
            tokensLimit: _tokensLimit,
            tokensMinted: 0,
            minDeposit: _minDeposit,
            maxDeposit: _maxDeposit,
            startBlock: _startBlock,
            endBlock: _endBlock,
            depositAddress: _depositAddress,
            depositAddressCheckedIn: false,
            finalised: false,
            exists: true                      
        });
         
        salesAgentsAddresses.push(_saleAddress);
    }


     
    function setSaleContractFinalised(address _sender) isSalesContract(msg.sender) public returns(bool) {
         
        SalesAgentInterface saleAgent = SalesAgentInterface(msg.sender);
         
        assert(!salesAgents[msg.sender].finalised);                       
         
        assert(salesAgents[msg.sender].depositAddress == _sender);            
         
        if (salesAgents[msg.sender].endBlock == 0) {
            salesAgents[msg.sender].endBlock = block.number;
        }
         
        assert(block.number >= salesAgents[msg.sender].endBlock);         
         
        assert(saleAgent.contributedTotal() >= salesAgents[msg.sender].targetEthMin);
         
        salesAgents[msg.sender].finalised = true;
         
        SaleFinalised(msg.sender, _sender, salesAgents[msg.sender].tokensMinted);
         
        return true;
    }


     
     
    function setSaleContractDepositAddressVerified(address _verifyAddress) isSalesContract(msg.sender) public {
         
        assert(salesAgents[msg.sender].depositAddress == _verifyAddress && _verifyAddress != 0x0);
         
        salesAgents[msg.sender].depositAddressCheckedIn = true;
    }

     
     
    function getSaleContractIsFinalised(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(bool) {
        return salesAgents[_salesAgentAddress].finalised;
    }

     
     
    function getSaleContractTargetEtherMin(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
        return salesAgents[_salesAgentAddress].targetEthMin;
    }

     
     
    function getSaleContractTargetEtherMax(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
        return salesAgents[_salesAgentAddress].targetEthMax;
    }

     
     
    function getSaleContractDepositEtherMin(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
        return salesAgents[_salesAgentAddress].minDeposit;
    }

     
     
    function getSaleContractDepositEtherMax(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
        return salesAgents[_salesAgentAddress].maxDeposit;
    }

     
     
    function getSaleContractDepositAddress(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(address) {
        return salesAgents[_salesAgentAddress].depositAddress;
    }

     
     
    function getSaleContractDepositAddressVerified(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(bool) {
        return salesAgents[_salesAgentAddress].depositAddressCheckedIn;
    }

     
     
    function getSaleContractStartBlock(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
        return salesAgents[_salesAgentAddress].startBlock;
    }

     
     
    function getSaleContractEndBlock(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
        return salesAgents[_salesAgentAddress].endBlock;
    }

     
     
    function getSaleContractTokensLimit(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
        return salesAgents[_salesAgentAddress].tokensLimit;
    }

     
     
    function getSaleContractTokensMinted(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
        return salesAgents[_salesAgentAddress].tokensMinted;
    }

    
}