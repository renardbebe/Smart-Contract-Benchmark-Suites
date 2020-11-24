 

pragma solidity ^0.4.25;

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

contract IERC20 {

    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public;
    function transferFrom(address from, address to, uint256 value) public;
    function approve(address spender, uint256 value) external;
    function allowance(address owner, address spender) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract IBTCToken is IERC20 {

    using SafeMath for uint256;

     
    string public name = "IBTC";
    string public symbol = "IBTC";
    uint public decimals = 18;

    uint public _totalSupply = 50000000e18;
    uint public _tokenLeft = 50000000e18;
    uint public _round1Limit = 2300000e18;
    uint public _round2Limit = 5300000e18;
    uint public _round3Limit = 9800000e18;
    uint public _developmentReserve = 40200000e18;
    uint public _endDate = 1544918399;
    uint public _minInvest = 0.5 ether;
    uint public _maxInvest = 100 ether;

     
    mapping (address => uint256) _investedEth;
     
    mapping (address => uint256) balances;

     
    mapping (address => mapping(address => uint256)) allowed;

     
    address public owner;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
     
     
    constructor() public payable {
        owner = 0x9FD6977e609AA945C6b6e40537dCF0A791775279;

        balances[owner] = _totalSupply; 
    }

     
     
    function () external payable {
        tokensale(msg.sender);
    }

     
     
     
    function tokensale(address recipient) public payable {
        require(recipient != 0x0);
        
        uint256 weiAmount = msg.value;
        uint tokens = weiAmount.mul(getPrice());
        
        _investedEth[msg.sender] = _investedEth[msg.sender].add(weiAmount);
        
        require( weiAmount >= _minInvest );
        require(_investedEth[msg.sender] <= _maxInvest);
        require(_tokenLeft >= tokens + _developmentReserve);

        balances[owner] = balances[owner].sub(tokens);
        balances[recipient] = balances[recipient].add(tokens);

        _tokenLeft = _tokenLeft.sub(tokens);
        
        owner.transfer(msg.value);
        TokenPurchase(msg.sender, recipient, weiAmount, tokens);
    }

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
     
     
    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }

     
    function sendIBTCToken(address to, uint256 value) public onlyOwner {
        require (
            to != 0x0 && value > 0 && _tokenLeft >= value
        );

        balances[owner] = balances[owner].sub(value);
        balances[to] = balances[to].add(value);
        _tokenLeft = _tokenLeft.sub(value);
        Transfer(owner, to, value);
    }

    function sendIBTCTokenToMultiAddr(address[] memory listAddresses, uint256[] memory amount) public onlyOwner {
        require(listAddresses.length == amount.length); 
         for (uint256 i = 0; i < listAddresses.length; i++) {
                require(listAddresses[i] != 0x0); 
                balances[listAddresses[i]] = balances[listAddresses[i]].add(amount[i]);
                balances[owner] = balances[owner].sub(amount[i]);
                Transfer(owner, listAddresses[i], amount[i]);
                _tokenLeft = _tokenLeft.sub(amount[i]);
         }
    }

    function destroyIBTCToken(address to, uint256 value) public onlyOwner {
        require (
                to != 0x0 && value > 0 && _totalSupply >= value
            );
        balances[to] = balances[to].sub(value);
    }

     
     
     
     
    function transfer(address to, uint256 value) public {
        require (
            balances[msg.sender] >= value && value > 0
        );
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
    }

     
     
     
     
     
    function transferFrom(address from, address to, uint256 value) public {
        require (
            allowed[from][msg.sender] >= value && balances[from] >= value && value > 0
        );
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
    }

     
     
     
     
     
    function approve(address spender, uint256 value) external {
        require (
            balances[msg.sender] >= value && value > 0
        );
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
    }

     
     
     
     
    function allowance(address _owner, address spender) public view returns (uint256) {
        return allowed[_owner][spender];
    }

     
     
    function getPrice() public constant returns (uint result) {
        if ( _totalSupply - _tokenLeft < _round1Limit )
            return 650;
        else if ( _totalSupply - _tokenLeft < _round2Limit )
            return 500;
        else if ( _totalSupply - _tokenLeft < _round3Limit )
            return 400;
        else
            return 0;
    }

    function getTokenDetail() public view returns (string memory, string memory, uint256) {
	    return (name, symbol, _totalSupply);
    }
}