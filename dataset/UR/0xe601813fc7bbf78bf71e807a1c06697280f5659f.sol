 

pragma solidity ^0.4.23;

  

 
contract ERC223ReceivingContract {

     
     
     
     
    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);  
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b != 0);
        return a % b;
    }
}

 
contract Token {
     
    uint256 public totalSupply;

     
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract StandardToken is Token {

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

     
     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != 0x0);

         
         
         
         
        require(_value == 0 || allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
     
     
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}


 
contract Vitalik2XToken is StandardToken {
    using SafeMath for uint256;

     
    string constant public symbol = "V2X";
    string constant public name = "Vitalik2X";
    uint256 constant public decimals = 18;
    uint256 constant public multiplier = 10 ** decimals;

    address public owner;

    uint256 public creationBlock;
    uint256 public mainPotTokenBalance;
    uint256 public mainPotETHBalance;

    mapping (address => uint256) blockLock;

    event Mint(address indexed to, uint256 amount);
    event DonatedTokens(address indexed donator, uint256 amount);
    event DonatedETH(address indexed donator, uint256 amount);
    event SoldTokensFromPot(address indexed seller, uint256 amount);
    event BoughtTokensFromPot(address indexed buyer, uint256 amount);
     
     
    constructor() public {
        owner = msg.sender;
        totalSupply = 10 ** decimals;
        balances[msg.sender] = totalSupply;
        creationBlock = block.number;

        emit Transfer(0x0, msg.sender, totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
     
    function donateTokensToMainPot(uint256 amount) external returns (bool){
        require(_transfer(this, amount));
        mainPotTokenBalance = mainPotTokenBalance.add(amount);
        emit DonatedTokens(msg.sender, amount);
        return true;
    }

    function donateETHToMainPot() external payable returns (bool){
        require(msg.value > 0);
        mainPotETHBalance = mainPotETHBalance.add(msg.value);
        emit DonatedETH(msg.sender, msg.value);
        return true;
    }

     
    function sellTokensToPot(uint256 amount) external returns (bool) {
        uint256 amountBeingPaid = ethSliceAmount(amount);
        require(amountBeingPaid <= ethSliceCap(), "Token amount sent is above the cap.");
        require(_transfer(this, amount));
        mainPotTokenBalance = mainPotTokenBalance.add(amount);
        mainPotETHBalance = mainPotETHBalance.sub(amountBeingPaid);
        msg.sender.transfer(amountBeingPaid);
        emit SoldTokensFromPot(msg.sender, amount);
        return true;
    }

     
    function buyTokensFromPot() external payable returns (uint256) {
        require(msg.value > 0);
        uint256 amountBuying = tokenSliceAmount(msg.value);
        require(amountBuying <= tokenSliceCap(), "Msg.value is above the cap.");
        require(mainPotTokenBalance >= 1 finney, "Pot does not have enough tokens.");
        mainPotETHBalance = mainPotETHBalance.add(msg.value);
        mainPotTokenBalance = mainPotTokenBalance.sub(amountBuying);
        balances[address(this)] = balances[address(this)].sub(amountBuying);
        balances[msg.sender] = balances[msg.sender].add(amountBuying);
        emit Transfer(address(this), msg.sender, amountBuying);
        emit BoughtTokensFromPot(msg.sender, amountBuying);
        return amountBuying;
    }

     
     
     
    function blockLockOf(address _owner) external view returns (uint256) {
        return blockLock[_owner];
    }

     
    function withdrawETH() external onlyOwner {
        owner.transfer(address(this).balance.sub(mainPotETHBalance));
    }

     
    function withdrawToken(address token) external onlyOwner {
        require(token != address(this));
        Token erc20 = Token(token);
        erc20.transfer(owner, erc20.balanceOf(this));
    }

     
     
    function ethSliceAmount(uint256 amountOfTokens) public view returns (uint256) {
        uint256 amountBuying = mainPotETHBalance.mul(amountOfTokens).div(mainPotTokenBalance);
        amountBuying = amountBuying.sub(amountBuying.mul(amountOfTokens).div(mainPotTokenBalance));
        return amountBuying;
    }

     
    function ethSliceCap() public view returns (uint256) {
        return mainPotETHBalance.mul(30).div(100);
    }

     
    function ethSlicePercentage(uint256 amountOfTokens) public view returns (uint256) {
        uint256 amountOfTokenRecieved = ethSliceAmount(amountOfTokens);
        return amountOfTokenRecieved.mul(100).div(mainPotETHBalance);
    }

     
    function tokenSliceAmount(uint256 amountOfETH) public view returns (uint256) {
        uint256 amountBuying = mainPotTokenBalance.mul(amountOfETH).div(mainPotETHBalance);
        amountBuying = amountBuying.sub(amountBuying.mul(amountOfETH).div(mainPotETHBalance));
        return amountBuying;
    }

     
    function tokenSliceCap() public view returns (uint256) {
        return mainPotTokenBalance.mul(30).div(100);
    }
     
    function tokenSlicePercentage(uint256 amountOfEth) public view returns (uint256) {
        uint256 amountOfEthRecieved = tokenSliceAmount(amountOfEth);
        return amountOfEthRecieved.mul(100).div(mainPotTokenBalance);
    }

     
    function accountLocked() public view returns (bool) {
        return (block.number < blockLock[msg.sender]);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(block.number >= blockLock[msg.sender], "Address is still locked.");
        if (_to == address(this)) {
            return _vitalikize(msg.sender, _value);
        } else {
            return _transfer(_to, _value);
        }
    }


     
     
     
     
     
     
     
    function transfer(
        address _to,
        uint256 _value,
        bytes _data)
        public
        returns (bool)
    {
        require(_to != address(this));
         
        require(transfer(_to, _value));

        uint codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

         
        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }

        return true;
    }

     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool)
    {
        require(block.number >= blockLock[_from], "Address is still locked.");
        require(_from != 0x0);
        require(_to != 0x0);
        require(_to != address(this));
         
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

     
     
     
     
     
     
    function _transfer(address _to, uint256 _value) internal returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function _vitalikize(address _sender, uint256 _value) internal returns (bool) {
        require(balances[_sender] >= _value, "Owner doesnt have enough tokens.");
        uint256 calcBlockLock = (block.number - creationBlock)/5;
        blockLock[_sender] = block.number + (calcBlockLock > 2600 ? calcBlockLock : 2600);
        require(mint(_sender, _value), "Minting failed");
        emit Transfer(address(0), _sender, _value);
        return true;
    }

    function mint(address _address, uint256 _amount) internal returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_address] = balances[_address].add(_amount);
        return true;
    }
}