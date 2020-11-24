 

 
 
pragma solidity ^0.4.18;

 

library SafeMath {

  function mul(uint a, uint b) internal constant returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal constant returns(uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal constant returns(uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal constant returns(uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

 

contract ERC20 {
    uint public totalSupply = 0;

    mapping(address => uint) balances;
    mapping(address => mapping (address => uint)) allowed;

    function balanceOf(address _owner) constant returns (uint);
    function transfer(address _to, uint _value) returns (bool);
    function transferFrom(address _from, address _to, uint _value) returns (bool);
    function approve(address _spender, uint _value) returns (bool);
    function allowance(address _owner, address _spender) constant returns (uint);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

} 

 
contract PhenomTeam {
     
    using SafeMath for uint;
    PhenomDemoToken public PHN = new PhenomDemoToken(this);

    
     
    uint public rateEth = 878;  

     
    address public Company;
    address public Manager;  
    address public Controller_Address1;  
    address public Controller_Address2;  
    address public Controller_Address3;  
    address public Oracle;  

     
    enum StatusICO {
        Created,
        Started,
        Paused,
        Finished
    }
    StatusICO statusICO = StatusICO.Created;
    
     
    event LogStartICO();
    event LogPause();
    event LogFinishICO();
    event LogBuyForInvestor(address investor, uint DTRCValue, string txHash);

     
     
    modifier managerOnly { 
        require(
            msg.sender == Manager
        );
        _; 
     }

     
    modifier oracleOnly { 
        require(msg.sender == Oracle);
        _; 
     }
     
    modifier controllersOnly {
        require(
            (msg.sender == Controller_Address1)||
            (msg.sender == Controller_Address2)||
            (msg.sender == Controller_Address3)
        );
        _;
    }

    
    function PhenomTeam(
        address _Company,
        address _Manager,
        address _Controller_Address1,
        address _Controller_Address2,
        address _Controller_Address3,
        address _Oracle
        ) public {
        Company = _Company;
        Manager = _Manager;
        Controller_Address1 = _Controller_Address1;
        Controller_Address2 = _Controller_Address2;
        Controller_Address3 = _Controller_Address3;
        Oracle = _Oracle;
    }

    
    function setRate(uint _rateEth) external oracleOnly {
        rateEth = _rateEth;
    }

    
    function startIco() external managerOnly {
        require(statusICO == StatusICO.Created || statusICO == StatusICO.Paused);
        statusICO = StatusICO.Started;
        LogStartICO();
    }

    
    function pauseIco() external managerOnly {
       require(statusICO == StatusICO.Started);
       statusICO = StatusICO.Paused;
       LogPause();
    }

    
    function finishIco() external managerOnly {
        require(statusICO == StatusICO.Started || statusICO == StatusICO.Paused);
        statusICO = StatusICO.Finished;
        LogFinishICO();
    }

    
    function() external payable {
        buy(msg.sender, msg.value.mul(rateEth)); 
    }

    

    function buyForInvestor(
        address _investor, 
        uint _PHNValue, 
        string _txHash
    ) 
        external 
        controllersOnly {
        buy(_investor, _PHNValue);
        LogBuyForInvestor(_investor, _PHNValue, _txHash);
    }

    
    function buy(address _investor, uint _PHNValue) internal {
        require(statusICO == StatusICO.Started);
        PHN.mintTokens(_investor, _PHNValue);
    }

    
    function unfreeze() external managerOnly {
       PHN.defrost();
    }

    
    function freeze() external managerOnly {
       PHN.frost();
    }

       
    function setWithdrawalAddress(address _Company) external managerOnly {
        Company = _Company;
    }
   
    
    function withdrawEther() external managerOnly {
        Company.transfer(this.balance);
    }

}

 
contract PhenomDemoToken is ERC20 {
    using SafeMath for uint;
    string public name = "ICO Platform Demo | https://Phenom.Team ";
    string public symbol = "PHN";
    uint public decimals = 18;

     
    address public ico;
    
     
    bool public tokensAreFrozen = true;

     
    modifier icoOnly { 
        require(msg.sender == ico); 
        _; 
    }

    
    function PhenomDemoToken(address _ico) public {
       ico = _ico;
    }

    
    function mintTokens(address _holder, uint _value) external icoOnly {
       require(_value > 0);
       balances[_holder] = balances[_holder].add(_value);
       totalSupply = totalSupply.add(_value);
       Transfer(0x0, _holder, _value);
    }


    
    function defrost() external icoOnly {
       tokensAreFrozen = false;
    }

    
    function frost() external icoOnly {
       tokensAreFrozen = true;
    }

    
    function balanceOf(address _holder) constant returns (uint) {
         return balances[_holder];
    }

    
    function transfer(address _to, uint _amount) public returns (bool) {
        require(!tokensAreFrozen);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

    
    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        require(!tokensAreFrozen);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
     }


    
    function approve(address _spender, uint _amount) public returns (bool) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    
    function allowance(address _owner, address _spender) constant returns (uint) {
        return allowed[_owner][_spender];
    }
}