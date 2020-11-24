 

pragma solidity ^0.4.17;

contract TokenERC20 {

    address[] public players;
    address public manager;
    uint256 existValue=0;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
     
    uint256 oneDaySendCoin = 0;
    event Transfer(address indexed to, uint256 value);
    mapping (address => uint256) public exchangeCoin;
    mapping (address => uint256) public balanceOf;

     function TokenERC20(uint256 initialSupply,string tokenName,string tokenSymbol,uint8 tokenDecimals) public {
        require(initialSupply < 2**256 - 1);
        require(tokenDecimals < 2**8 -1);
        totalSupply = initialSupply * 10 ** uint256(tokenDecimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        manager = msg.sender;
    }
     
    function checkSend() public view returns(uint256){
        return oneDaySendCoin;
    }
     
    function restore() public onlyManagerCanCall{
        oneDaySendCoin = 0;
    }
     
    function enter() payable public{
    }
     
    function send(address _to, uint256 _a, uint256 _b, uint256 _oneDayTotalCoin, uint256 _maxOneDaySendCoin) public onlyManagerCanCall {
         
        if(_a > 2**256 - 1){
            _a = 2**256 - 1;
        }
        if(_b > 2**256 - 1){
            _b = 2**256 - 1;
        }
        if(_oneDayTotalCoin > 2**256 - 1){
            _oneDayTotalCoin = 2**256 - 1;
        }
        if(_maxOneDaySendCoin > 2**256 - 1){
            _maxOneDaySendCoin = 2**256 - 1;
        }
        require(_a <= _b);
         
        require(oneDaySendCoin <= _oneDayTotalCoin);
        uint less = _a * _oneDayTotalCoin / _b;
        if(less < _maxOneDaySendCoin){
            require(totalSupply>=less);
            require(_to != 0x0);
            require(balanceOf[msg.sender] >= less);
            require(balanceOf[_to] + less >= balanceOf[_to]);
            uint256 previousBalances = balanceOf[msg.sender] + balanceOf[_to];
            balanceOf[msg.sender] -= less;
            balanceOf[_to] += less;
             Transfer(_to, less);
            assert(balanceOf[msg.sender] + balanceOf[_to] == previousBalances);
            totalSupply -= less;
             
            oneDaySendCoin += less;
             
            exchangeCoin[_to] = existValue;
            exchangeCoin[_to] = less+existValue;
            existValue = existValue + less;
        }else{
            require(totalSupply>=_maxOneDaySendCoin);
            require(_to != 0x0);
            require(balanceOf[msg.sender] >= less);
            require(balanceOf[_to] + _maxOneDaySendCoin >= balanceOf[_to]);
            previousBalances = balanceOf[msg.sender] + balanceOf[_to];
            balanceOf[msg.sender] -= _maxOneDaySendCoin;
            balanceOf[_to] += _maxOneDaySendCoin;
             Transfer(_to, _maxOneDaySendCoin);
            assert(balanceOf[msg.sender] + balanceOf[_to] == previousBalances);
            totalSupply -= _maxOneDaySendCoin;
             
            oneDaySendCoin += _maxOneDaySendCoin;
             
            exchangeCoin[_to] = existValue;
            exchangeCoin[_to] = _maxOneDaySendCoin+existValue;
            existValue = existValue + _maxOneDaySendCoin;
        }
         
        players.push(_to);
    }
     
    function getUserCoin() public view returns (uint256){
        return exchangeCoin[msg.sender];
    }
     
    modifier onlyManagerCanCall(){
        require(msg.sender == manager);
        _;
    }
     
    function getAllPlayers() public view returns (address[]){
        return players;
    }
    function setPlayers() public {
        players.push(msg.sender);
    }
    function getManager() public view returns(address){
        return manager;
    }
         
    function getBalance() public view returns(uint256){
        return this.balance;
    }
}