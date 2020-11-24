 

pragma solidity ^0.4.10;

 
contract SafeMath {

     
     
     
     
     
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
contract Indicoin is StandardToken, SafeMath {

     
    string public constant name = "Indicoin";
    string public constant symbol = "INDI";
    uint256 public constant decimals = 18;
    string public version = "1.0";

     
    address public ethFundDeposit;       
    address public indiFundAndSocialVaultDeposit;       
    address public bountyDeposit;  
    address public saleDeposit;  
     
    bool public isFinalized;               
    uint256 public fundingStartTime;
    uint256 public fundingEndTime;
    uint256 public constant indiFundAndSocialVault = 350 * (10**6) * 10**decimals;    
    uint256 public constant bounty = 50 * (10**6) * 10**decimals;  
    uint256 public constant sale = 200 * (10**6) * 10**decimals; 
    uint256 public constant tokenExchangeRate = 12500;  
    uint256 public constant tokenCreationCap =  1000 * (10**6) * 10**decimals;
    uint256 public constant tokenCreationMin =  600 * (10**6) * 10**decimals;


     
    event LogRefund(address indexed _to, uint256 _value);
    event CreateINDI(address indexed _to, uint256 _value);
    

    
    function Indicoin()
    {
      isFinalized = false;                    
      ethFundDeposit = 0xe16927243587d3293574235314D96B3501fC00b7;
      indiFundAndSocialVaultDeposit = 0xF83EA33530027A4Fd7F37629E18508E124DFB99D;
      saleDeposit = 0xC1E5214983d18b80c9Cdd5d2edAC40B7d8ddfCB9;
      bountyDeposit = 0xB41A19abF814375D89222834aeE3FB264e4b5e77;
      fundingStartTime = 1507309861;
      fundingEndTime = 1509580799;
      
      totalSupply = indiFundAndSocialVault + bounty + sale;
      balances[indiFundAndSocialVaultDeposit] = indiFundAndSocialVault;  
      balances[bountyDeposit] = bounty;  
      balances[saleDeposit] = sale;  
      CreateINDI(indiFundAndSocialVaultDeposit, indiFundAndSocialVault);   
      CreateINDI(bountyDeposit, bounty);  
      CreateINDI(saleDeposit, sale);  
    }
    
    
     
    function createTokens() payable external {
      if (isFinalized) revert();
      if (now < fundingStartTime) revert();
      if (now > fundingEndTime) revert();
      if (msg.value == 0) revert();

      uint256 tokens = safeMult(msg.value, tokenExchangeRate);  
      uint256 checkedSupply = safeAdd(totalSupply, tokens);

       
      if (tokenCreationCap < checkedSupply) revert();   

      totalSupply = checkedSupply;
      balances[msg.sender] += tokens;   
      CreateINDI(msg.sender, tokens);   
    }

     
    function finalize() external {
      if (isFinalized) revert();
      if (msg.sender != ethFundDeposit) revert();  
      if(totalSupply < tokenCreationMin) revert();       
      if(now <= fundingEndTime && totalSupply != tokenCreationCap) revert();
       
      isFinalized = true;
      if(!ethFundDeposit.send(this.balance)) revert();   
    }

     
    function refund() external {
      if(isFinalized) revert();                        
      if (now <= fundingEndTime) revert();  
      if(totalSupply >= tokenCreationMin) revert();   
      if(msg.sender == indiFundAndSocialVaultDeposit) revert();     
      uint256 indiVal = balances[msg.sender];
      if (indiVal == 0) revert();
      balances[msg.sender] = 0;
      totalSupply = safeSubtract(totalSupply, indiVal);  
      uint256 ethVal = indiVal / tokenExchangeRate;      
      LogRefund(msg.sender, ethVal);                
      if (!msg.sender.send(ethVal)) revert();        
    }

}