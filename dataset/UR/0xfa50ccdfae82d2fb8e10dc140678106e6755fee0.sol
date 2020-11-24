 

pragma solidity ^0.4.18;


contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {

        require(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }


}


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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


contract Token {
     
     
     
    function totalSupply() view public returns (uint256 supply);

     
     
    function balanceOf(address _owner) view public returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public;

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public;

     
     
     
     
    function approve(address _spender, uint256 _value) public;

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract WBC is Token, Owned {
     
    using SafeMath for uint256;

    string public constant name    = "WEBIC Token";   
    uint8 public constant decimals = 6;                
    string public constant symbol  = "WEBIC";             


    uint totoals=0;
     
    mapping(address => uint256) balances;
     
    mapping(address => mapping(address => uint256)) allowed;



     
    constructor() public {
    }


    function totalSupply() public view returns (uint256 supply){
        return totoals;
    }


    function () public {
        revert();
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


     
    function transfer(address _to, uint256 _amount) public {
        require(_amount > 0);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);

    }
    
    
     

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public {

        require(allowed[_from][msg.sender] >= _amount && _amount > 0);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit  Transfer(_from, _to, _amount);
    }

     
     
    function approve(address _spender, uint256 _amount) public {
        allowed[msg.sender][_spender] = _amount;
        emit  Approval(msg.sender, _spender, _amount);
    }


    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function mint(address _owner, uint256 _amount) public onlyOwner  {
        balances[_owner] = balances[_owner].add(_amount);
        totoals = totoals.add(_amount);
        emit  Transfer(0, _owner, _amount);
    }

}



contract wbcSale is Owned {
  
    using SafeMath for uint256;

    uint256 public constant totalSupply         = (12*10 ** 8) * (10 ** 6);  
    uint256 constant raiseSupply                =  totalSupply * 35 / 100; 
    uint256 constant reservedForTeam1           = totalSupply * 10 / 100;  
    uint256 constant reservedForTeam2           = totalSupply * 40 / 100; 
    uint256 constant reservedForTeam3           = totalSupply * 15 / 100; 

    WBC wbc; 
    address raiseAccount;  
    address team1Account;  
    address team2Account;  
    address team3Account;  
    uint32 startTime=1533283200;

    bool public initialized=false;
    bool public finalized=false;



    constructor() public {

    }





    function blockTime() public view returns (uint32) {
        return uint32(block.timestamp);
    }




    

  


    function () public payable {
        revert();
    }



    function mintToTeamAccounts() internal onlyOwner{
        require(!initialized);
        wbc.mint(raiseAccount,raiseSupply);
        wbc.mint(team1Account,reservedForTeam1);
        wbc.mint(team2Account,reservedForTeam2);
        wbc.mint(team3Account,reservedForTeam3);
    }

     
     
    function initialize (
        WBC _wbc,address raiseAcc,address team1Acc,address team2Acc,address team3Acc) public onlyOwner {
        require(blockTime()>=startTime);
         
        require(_wbc.owner() == address(this));
        require(raiseAcc!=0&&team1Acc != 0&&team2Acc != 0&&team3Acc != 0);
        wbc = _wbc;
        raiseAccount = raiseAcc;
        team1Account = team1Acc;
        team2Account = team2Acc;
        team3Account = team3Acc;
        mintToTeamAccounts();
        initialized = true;
        emit onInitialized();
    }

     
    function finalize() public onlyOwner {
        require(!finalized);
         
        finalized = true;
        emit onFinalized();
    }

    event onInitialized();
    event onFinalized();
}