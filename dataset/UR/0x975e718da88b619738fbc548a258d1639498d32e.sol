 

pragma solidity ^0.4.18;

 
contract SafeMath {
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

 
 
 
contract Token is SafeMath {
     
     
    function totalSupply() public constant returns (uint256 supply);

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
     
     
    function transferTo(address _to, uint256 _value) public returns (bool);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
contract StdToken is Token {
     
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint public supply = 0;

     
    function transferTo(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value > balances[_to]);

        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);

        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value > balances[_to]);

        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);

        Transfer(_from, _to, _value);
        return true;
    }

    function totalSupply() public constant returns (uint256) {
        return supply;
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }
}
 
contract EvoNineToken is StdToken
{
     
    string public name = "";
    string public symbol = "EVG";
    string public website = "https://evonine.co";
    uint public decimals = 18;

    uint public constant TOTAL_SUPPLY = 19000000 * (1 ether / 1 wei);
    uint public constant DEVELOPER_BONUS = 4500000 * (1 ether / 1 wei);
    uint public constant TEAM_BONUS = 3800000 * (1 ether / 1 wei);
    uint public constant ECO_SYSTEM_BONUS = 5700000 * (1 ether / 1 wei);
    uint public constant CONTRACT_HOLDER_BONUS = 5000000 * (1 ether / 1 wei);

    uint public constant ICO_PRICE1 = 2000;      
    uint public constant ICO_PRICE2 = 1818;      
    uint public constant ICO_PRICE3 = 1666;      
    uint public constant ICO_PRICE4 = 1538;      
    uint public constant ICO_PRICE5 = 1250;      
    uint public constant ICO_PRICE6 = 1000;      
    uint public constant ICO_PRICE7 = 800;      
    uint public constant ICO_PRICE8 = 666;      

    enum State{
        Init,
        Paused,
        ICORunning,
        ICOFinished
    }

    State public currentState = State.Init;
    bool public enableTransfers = true;

     
     
    address public tokenManagerAddress = 0;

     
    address public escrowAddress = 0;

     
    address public teamAddress = 0;

     
    address public developmentAddress = 0;

     
    address public ecoSystemAddress = 0;

     
    address public contractHolderAddress = 0;


    uint public icoSoldTokens = 0;
    uint public totalSoldTokens = 0;

     
    modifier onlytokenManagerAddress()
    {
        require(msg.sender == tokenManagerAddress);
        _;
    }

    modifier onlyTokenCrowner()
    {
        require(msg.sender == escrowAddress);
        _;
    }

    modifier onlyInState(State state)
    {
        require(state == currentState);
        _;
    }

     
    event LogBuy(address indexed owner, uint value);
    event LogBurn(address indexed owner, uint value);

     
     
     
     
     
     
     
     
    function EvoNineToken(string _name, address _tokenManagerAddress, address _escrowAddress, address _teamAddress, address _developmentAddress, address _ecoSystemAddress, address _contractHolderAddress) public
    {
        name = _name;
        tokenManagerAddress = _tokenManagerAddress;
        escrowAddress = _escrowAddress;
        teamAddress = _teamAddress;
        developmentAddress = _developmentAddress;
        ecoSystemAddress = _ecoSystemAddress;
        contractHolderAddress = _contractHolderAddress;

        balances[_contractHolderAddress] += TOTAL_SUPPLY;
        supply += TOTAL_SUPPLY;
    }

    function buyTokens() public payable returns (uint256)
    {
        require(msg.value >= ((1 ether / 1 wei) / 100));
        uint newTokens = msg.value * getPrice();
        balances[msg.sender] += newTokens;
        supply += newTokens;
        icoSoldTokens += newTokens;
        totalSoldTokens += newTokens;

        LogBuy(msg.sender, newTokens);
    }

    function getPrice() public constant returns (uint)
    {
        if (icoSoldTokens < (4100000 * (1 ether / 1 wei))) {
            return ICO_PRICE1;
        }
        if (icoSoldTokens < (4300000 * (1 ether / 1 wei))) {
            return ICO_PRICE2;
        }
        if (icoSoldTokens < (4700000 * (1 ether / 1 wei))) {
            return ICO_PRICE3;
        }
        if (icoSoldTokens < (5200000 * (1 ether / 1 wei))) {
            return ICO_PRICE4;
        }
        if (icoSoldTokens < (6000000 * (1 ether / 1 wei))) {
            return ICO_PRICE5;
        }
        if (icoSoldTokens < (7000000 * (1 ether / 1 wei))) {
            return ICO_PRICE6;
        }
        if (icoSoldTokens < (8000000 * (1 ether / 1 wei))) {
            return ICO_PRICE7;
        }
        return ICO_PRICE8;
    }

    function setState(State _nextState) public onlytokenManagerAddress
    {
         
        require(currentState != State.ICOFinished);

        currentState = _nextState;
         
         
         
    }

    function DisableTransfer() public onlytokenManagerAddress
    {
        enableTransfers = false;
    }


    function EnableTransfer() public onlytokenManagerAddress
    {
        enableTransfers = true;
    }

    function withdrawEther() public onlytokenManagerAddress
    {
        if (this.balance > 0)
        {
            escrowAddress.transfer(this.balance);
        }
    }

     
    function transferTo(address _to, uint256 _value) public returns (bool){
        require(enableTransfers);
        return super.transferTo(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        require(enableTransfers);
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(enableTransfers);
        return super.approve(_spender, _value);
    }

     
    function ChangetokenManagerAddress(address _mgr) public onlytokenManagerAddress
    {
        tokenManagerAddress = _mgr;
    }

     
    function ChangeCrowner(address _mgr) public onlyTokenCrowner
    {
        escrowAddress = _mgr;
    }
}