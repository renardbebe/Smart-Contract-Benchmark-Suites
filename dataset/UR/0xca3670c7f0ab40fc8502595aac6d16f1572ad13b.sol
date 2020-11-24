 

pragma solidity ^0.4.18;

 
 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address _who) public constant returns (uint);
  function allowance(address _owner, address _spender) public constant returns (uint);

  function transfer(address _to, uint _value) public returns (bool ok);
  function transferFrom(address _from, address _to, uint _value) public returns (bool ok);
  function approve(address _spender, uint _value) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
 
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
 
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ITToken is ERC20, Ownable, SafeMath {

     
    string public constant name = "INFINITY TRAVEL TOKEN";
    string public constant symbol = "ITT";
    uint256 public constant decimals = 18;  

     
    uint256 public startWithdraw;

     
    address public ITTMultisig;

     
    address public ethExchangeWallet;

    uint256 public tokensPerEther = 1000;

    bool public startStop = false;

    mapping (address => uint256) public walletAngelPESales;
    mapping (address => uint256) public walletFoundingInitiatorSales;

    mapping (address => uint256) public releasedAngelPESales;
    mapping (address => uint256) public releasedFoundingInitiatorSales;

    mapping (uint => address) public walletAddresses;

     
    mapping (address => uint256) balances;
     
    mapping (address => mapping (address => uint256)) allowed;

    function ITToken() public {
        totalSupply = 500000000 ether;
        balances[msg.sender] = totalSupply;
    }

     
     
     
    function addWalletAddresses(uint _id, address _walletAddress) onlyOwner external{
        require(_walletAddress != address(0));
        walletAddresses[_id] = _walletAddress;
    }

     
     
    function setITTMultiSig(address _ittMultisig) onlyOwner external{
        require(_ittMultisig != address(0));
        ITTMultisig = _ittMultisig;
    }

     
     
    function setEthExchangeWallet(address _ethExchangeWallet) onlyOwner external {
        require(_ethExchangeWallet != address(0));
        ethExchangeWallet = _ethExchangeWallet;
    }

     
     
    function setTokensPerEther(uint256 _tokensPerEther) onlyOwner external {
        require(_tokensPerEther > 0);
        tokensPerEther = _tokensPerEther;
    }

    function startStopICO(bool status) onlyOwner external {
        startStop = status;
    }

    function startLockingPeriod() onlyOwner external {
        startWithdraw = now;
    }

     
    function assignToken(address _investor,uint256 _tokens) external {
         
        require(msg.sender == walletAddresses[0] || msg.sender == walletAddresses[1] || msg.sender == walletAddresses[2] || msg.sender == walletAddresses[3]);

         
        require(_investor != address(0) && _tokens > 0);
         
        require(_tokens <= balances[msg.sender]);
        
         
        balances[msg.sender] = safeSub(balances[msg.sender],_tokens);

         
        if(msg.sender == walletAddresses[0] || msg.sender == walletAddresses[1]){
            walletAngelPESales[_investor] = safeAdd(walletAngelPESales[_investor],_tokens);
        }
        else if(msg.sender == walletAddresses[2] || msg.sender == walletAddresses[3]){
            walletFoundingInitiatorSales[_investor] = safeAdd(walletFoundingInitiatorSales[_investor],_tokens);
        }
        else{
            revert();
        }
    }

    function withdrawTokens() public {
        require(walletAngelPESales[msg.sender] > 0 || walletFoundingInitiatorSales[msg.sender] > 0);
        uint256 withdrawableAmount = 0;

        if (walletAngelPESales[msg.sender] > 0) {
            uint256 withdrawableAmountANPES = getWithdrawableAmountANPES(msg.sender);
            walletAngelPESales[msg.sender] = safeSub(walletAngelPESales[msg.sender], withdrawableAmountANPES);
            releasedAngelPESales[msg.sender] = safeAdd(releasedAngelPESales[msg.sender],withdrawableAmountANPES);
            withdrawableAmount = safeAdd(withdrawableAmount, withdrawableAmountANPES);
        }
        if (walletFoundingInitiatorSales[msg.sender] > 0) {
            uint256 withdrawableAmountFIIT = getWithdrawableAmountFIIT(msg.sender);
            walletFoundingInitiatorSales[msg.sender] = safeSub(walletFoundingInitiatorSales[msg.sender], withdrawableAmountFIIT);
            releasedFoundingInitiatorSales[msg.sender] = safeAdd(releasedFoundingInitiatorSales[msg.sender], withdrawableAmountFIIT);
            withdrawableAmount = safeAdd(withdrawableAmount, withdrawableAmountFIIT);
        }
        require(withdrawableAmount > 0);
         
        balances[msg.sender] = safeAdd(balances[msg.sender], withdrawableAmount);
    }

     
    function getWithdrawableAmountANPES(address _investor) public view returns(uint256) {
        require(startWithdraw != 0);
         
        uint interval = safeDiv(safeSub(now,startWithdraw),30 days);
         
        uint _allocatedTokens = safeAdd(walletAngelPESales[_investor],releasedAngelPESales[_investor]);
         
        if (interval < 6) { 
            return (0); 
        } else if (interval >= 6 && interval < 12) {
            return safeSub(getPercentageAmount(25,_allocatedTokens), releasedAngelPESales[_investor]);
        } else if (interval >= 12 && interval < 18) {
            return safeSub(getPercentageAmount(50,_allocatedTokens), releasedAngelPESales[_investor]);
        } else if (interval >= 18 && interval < 24) {
            return safeSub(getPercentageAmount(75,_allocatedTokens), releasedAngelPESales[_investor]);
        } else if (interval >= 24) {
            return safeSub(_allocatedTokens, releasedAngelPESales[_investor]);
        }
    }

     
    function getWithdrawableAmountFIIT(address _investor) public view returns(uint256) {
        require(startWithdraw != 0);
         
        uint interval = safeDiv(safeSub(now,startWithdraw),30 days);
         
        uint _allocatedTokens = safeAdd(walletFoundingInitiatorSales[_investor],releasedFoundingInitiatorSales[_investor]);
         
        if (interval < 24) { 
            return (0); 
        } else if (interval >= 24) {
            return safeSub(_allocatedTokens, releasedFoundingInitiatorSales[_investor]);
        }
    }

    function getPercentageAmount(uint256 percent,uint256 _tokens) internal pure returns (uint256) {
        return safeDiv(safeMul(_tokens,percent),100);
    }

     
    function() payable external {
         
        require(startStop);

         
        require(msg.value >= (0.5 ether));

         
        uint256 calculatedTokens = safeMul(msg.value, tokensPerEther);

         
        require(balances[ethExchangeWallet] >= calculatedTokens);

         
        assignTokens(msg.sender, calculatedTokens);
    }

     
     
    function assignTokens(address investor, uint256 tokens) internal {
         
        balances[ethExchangeWallet] = safeSub(balances[ethExchangeWallet], tokens);

         
        balances[investor] = safeAdd(balances[investor], tokens);

         
        Transfer(ethExchangeWallet, investor, tokens);
    }

    function finalizeCrowdSale() external{
         
        require(ITTMultisig != address(0));
         
        require(ITTMultisig.send(address(this).balance));
    }

     
     
    function balanceOf(address _who) public constant returns (uint) {
        return balances[_who];
    }

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
    function transfer(address _to, uint _value) public returns (bool ok) {
         
        require(_to != 0 && _value > 0);
        uint256 senderBalance = balances[msg.sender];
         
        require(senderBalance >= _value);
        senderBalance = safeSub(senderBalance, _value);
        balances[msg.sender] = senderBalance;
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) public returns (bool ok) {
         
        require(_from != 0 && _to != 0 && _value > 0);
         
        require(allowed[_from][msg.sender] >= _value && balances[_from] >= _value);
        balances[_from] = safeSub(balances[_from],_value);
        balances[_to] = safeAdd(balances[_to],_value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
     
     
     
    function approve(address _spender, uint _value) public returns (bool ok) {
         
        require(_spender != 0);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

}