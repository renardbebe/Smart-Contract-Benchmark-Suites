 

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

contract ERC20 {
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
    
}


contract BasicToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

     

    function transfer(address _to, uint256 _value) returns (bool) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        }else {
            return false;
        }
    }
    

     

    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        uint256 _allowance = allowed[_from][msg.sender];
        allowed[_from][msg.sender] = _allowance.sub(_value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
}


     

    function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }


}

contract HRAToken is BasicToken {

    using SafeMath for uint256;

    string public name = "HERA";                                 
    string public symbol = "HRA";                                
    uint8 public decimals = 10;                                  
    uint256 public initialSupply = 30000000 * 10**10;            

     
    uint256 public totalAllocatedTokens;                          
    uint256 public tokensAllocatedToCrowdFund;                    

     
    address public founderMultiSigAddress;                       
    address public crowdFundAddress;                             

     
    event ChangeFoundersWalletAddress(uint256 _blockTimeStamp, address indexed _foundersWalletAddress);
    
     

    modifier nonZeroAddress(address _to){
        require(_to != 0x0);
        _;
    }

    modifier onlyFounders(){
        require(msg.sender == founderMultiSigAddress);
        _;
    }

    modifier onlyCrowdfund(){
        require(msg.sender == crowdFundAddress);
        _;
    }

     
    function HRAToken(address _crowdFundAddress, address _founderMultiSigAddress) {
        crowdFundAddress = _crowdFundAddress;
        founderMultiSigAddress = _founderMultiSigAddress;

         
        balances[crowdFundAddress] = initialSupply;
    }

     
    function changeTotalSupply(uint256 _amount) onlyCrowdfund {
        totalAllocatedTokens += _amount;
    }

     
    function changeFounderMultiSigAddress(address _newFounderMultiSigAddress) onlyFounders nonZeroAddress(_newFounderMultiSigAddress) {
        founderMultiSigAddress = _newFounderMultiSigAddress;
        ChangeFoundersWalletAddress(now, founderMultiSigAddress);
    }

}

contract HRACrowdfund {
    
    using SafeMath for uint256;

    HRAToken public token;                                     
    
    address public founderMulSigAddress;                       
    uint256 public exchangeRate;                               
    uint256 public ethRaised;                                  
    bool private tokenDeployed = false;                        
    uint256 public tokenSold;                                  
    uint256 public manualTransferToken;                        
    uint256 public tokenDistributeInDividend;                  
    uint8 internal EXISTS = 1;                                 
    uint8 internal NEW = 0;                                    

    address[] public investors;                                

    mapping (address => uint8) internal previousInvestor;
     
    event ChangeFounderMulSigAddress(address indexed _newFounderMulSigAddress , uint256 _timestamp);
    event ChangeRateOfToken(uint256 _timestamp, uint256 _newRate);
    event TokenPurchase(address indexed _beneficiary, uint256 _value, uint256 _amount);
    event AdminTokenSent(address indexed _to, uint256 _value);
    event SendDividend(address indexed _to , uint256 _value, uint256 _timestamp);
    
     
    modifier onlyfounder() {
        require(msg.sender == founderMulSigAddress);
        _;
    }

    modifier nonZeroAddress(address _to) {
        require(_to != 0x0);
        _;
    }

    modifier onlyPublic() {
        require(msg.sender != founderMulSigAddress);
        _;
    }

    modifier nonZeroEth() {
        require(msg.value != 0);
        _;
    }

    modifier isTokenDeployed() {
        require(tokenDeployed == true);
        _;
    }
    
     
    function HRACrowdfund(address _founderMulSigAddress) {
        founderMulSigAddress = _founderMulSigAddress;
        exchangeRate = 320;
    }
   
    
    function setToken(address _tokenAddress) nonZeroAddress(_tokenAddress) onlyfounder {
         require(tokenDeployed == false);
         token = HRAToken(_tokenAddress);
         tokenDeployed = true;
    }
    
     
    function changeExchangeRate(uint256 _rate) onlyfounder returns (bool) {
        if(_rate != 0){
            exchangeRate = _rate;
            ChangeRateOfToken(now,_rate);
            return true;
        }
        return false;
    }
    
     
    function ChangeFounderWalletAddress(address _newAddress) onlyfounder nonZeroAddress(_newAddress) {
         founderMulSigAddress = _newAddress;
         ChangeFounderMulSigAddress(founderMulSigAddress,now);
    }

     
    function buyTokens (address _beneficiary)
    onlyPublic
    nonZeroAddress(_beneficiary)
    nonZeroEth
    isTokenDeployed
    payable
    public
    returns (bool)
    {
        uint256 amount = (msg.value.mul(exchangeRate)).div(10 ** 8);
       
        require(checkExistence(_beneficiary));

        if (token.transfer(_beneficiary, amount)) {
            fundTransfer(msg.value);
            previousInvestor[_beneficiary] = EXISTS;
            ethRaised = ethRaised.add(msg.value);
            tokenSold = tokenSold.add(amount);
            token.changeTotalSupply(amount); 
            TokenPurchase(_beneficiary, msg.value, amount);
            return true;
        }
        return false;
    }

     
    function sendToken (address _to, uint256 _value)
    onlyfounder 
    nonZeroAddress(_to) 
    isTokenDeployed
    returns (bool)
    {
        if (_value == 0)
            return false;

        require(checkExistence(_to));
        
        uint256 _tokenAmount= _value * 10 ** uint256(token.decimals());

        if (token.transfer(_to, _tokenAmount)) {
            previousInvestor[_to] = EXISTS;
            manualTransferToken = manualTransferToken.add(_tokenAmount);
            token.changeTotalSupply(_tokenAmount); 
            AdminTokenSent(_to, _tokenAmount);
            return true;
        }
        return false;
    }
    
     
    function checkExistence(address _beneficiary) internal returns (bool) {
         if (token.balanceOf(_beneficiary) == 0 && previousInvestor[_beneficiary] == NEW) {
            investors.push(_beneficiary);
        }
        return true;
    }
    
     
    function provideDividend(uint256 _dividend) 
    onlyfounder 
    isTokenDeployed
    {
        uint256 _supply = token.totalAllocatedTokens();
        uint256 _dividendValue = _dividend.mul(10 ** uint256(token.decimals()));
        for (uint8 i = 0 ; i < investors.length ; i++) {
            
            uint256 _value = ((token.balanceOf(investors[i])).mul(_dividendValue)).div(_supply);
            dividendTransfer(investors[i], _value);
        }
    }
    
     
    function dividendTransfer(address _to, uint256 _value) private {
        if (token.transfer(_to,_value)) {
            token.changeTotalSupply(_value);
            tokenDistributeInDividend = tokenDistributeInDividend.add(_value);
            SendDividend(_to,_value,now);
        }
    }
    
     
    function fundTransfer(uint256 _funds) private {
        founderMulSigAddress.transfer(_funds);
    }
    
     
     
    function () payable {
        buyTokens(msg.sender);
    }

}