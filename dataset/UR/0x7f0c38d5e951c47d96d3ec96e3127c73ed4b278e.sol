 

pragma solidity ^0.4.17;

 
interface ERC20 {
     
    function totalSupply() public constant returns (uint _totalSupply);
     
    function balanceOf(address _owner) public constant returns (uint balance);
     
    function transfer(address _to, uint _value) public returns (bool success);
     
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
     
     
     
    function approve(address _spender, uint _value) public returns (bool success);
     
    function allowance(address _owner, address _spender) public constant returns (uint remaining);
     
    event Transfer(address indexed _from, address indexed _to, uint _value);
     
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}



contract OnePay is ERC20 {

     
    string public constant name = "OnePay";
    string public constant symbol = "1PAY";
    uint256 public constant decimals = 18;

     
    address public director;

     
    mapping(address => uint256) balances;

     
    mapping(address => mapping(address => uint256)) allowed;

     
    bool public saleClosed;
    uint256 public currentSalePhase;
    uint256 public SALE = 9090;   
    uint256 public PRE_SALE = 16667;  

     
    uint256 public totalSupply;

     
    uint256 public totalReceived;

     
    uint256 public mintedCoins;

     
    uint256 public hardCapSale;

     
    uint256 public tokenCap;

     
    modifier onlyDirector()
    {
        assert(msg.sender == director);
        _;
    }

     
    function OnePay() public
    {
         
        director = msg.sender;

         
        hardCapSale = 100000000 * 10 ** uint256(decimals);

         
        tokenCap = 500000000 * 10 ** uint256(decimals);

         
        totalSupply = 0;

         
        currentSalePhase = PRE_SALE;

         
        mintedCoins = 0;

         
        totalReceived = 0;

        saleClosed = true;
    }

     
    function() public payable
    {
                 
        require(!saleClosed);

         
        require(msg.value >= 0.02 ether);

         
        if (totalReceived >= 1500 ether) {
            currentSalePhase = SALE;
        }

        uint256 c = mul(msg.value, currentSalePhase);

         
        uint256 amount = c;

         
        require(mintedCoins + amount <= hardCapSale);

         
        balances[msg.sender] += amount;

         
        mintedCoins += amount;

         
        totalSupply += amount;

         
        totalReceived += msg.value;

        Transfer(this, msg.sender, amount);
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);  
        uint256 c = a / b;
        assert(a == b * c + a % b);  
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

     
    function getCompanyToken(uint256 amount) public onlyDirector returns (bool success)
    {
        amount = amount * 10 ** uint256(decimals);

        require((totalSupply + amount) <= tokenCap);

        balances[director] = amount;

        totalSupply += amount;

        return true;
    }

     
    function closeSale() public onlyDirector returns (bool success)
    {
        saleClosed = true;
        return true;
    }

     
    function openSale() public onlyDirector returns (bool success)
    {
        saleClosed = false;
        return true;
    }

     
    function setPriceToPreSale() public onlyDirector returns (bool success)
    {
        currentSalePhase = PRE_SALE;
        return true;
    }

     
    function setPriceToRegSale() public onlyDirector returns (bool success)
    {
        currentSalePhase = SALE;
        return true;
    }

     
    function withdrawFunds() public
    {
        director.transfer(this.balance);
    }

     
    function transferDirector(address newDirector) public onlyDirector
    {
        director = newDirector;
    }

     
    function totalSupply() public view returns (uint256)
    {
        return totalSupply;
    }

     
    function balanceOf(address _owner) public constant returns (uint256)
    {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {

         
        require(balances[msg.sender] >= _value && _value > 0);
         
        balances[msg.sender] = balances[msg.sender] - _value;

         
        balances[_to] = add(balances[_to], _value);

         
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    {
        require(allowed[_from][msg.sender] >= _value && balances[_from] >= _value && _value > 0);
        balances[_from] = balances[_from] - _value;
        balances[_to] = add(balances[_to], _value);
        allowed[_from][msg.sender] = sub(allowed[_from][msg.sender], _value);

        Transfer(_from, _to, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}