 

pragma solidity ^0.5.1;

contract Team {
    using SafeMath for uint256;

    address payable public teamAddressOne = 0x5947D8b85c5D3f8655b136B5De5D0Dd33f8E93D9;
    address payable public teamAddressTwo = 0xC923728AD95f71BC77186D6Fb091B3B30Ba42247;
    address payable public teamAddressThree = 0x763BFB050F9b973Dd32693B1e2181A68508CdA54;

    JackPot public JPContract;
    CBCToken public CBCTokenContract;

     
    function () external payable {
        require(JPContract.getState() && msg.value >= 0.05 ether);

        JPContract.setInfo(msg.sender, msg.value.mul(90).div(100));

        teamAddressOne.transfer(msg.value.mul(4).div(100));
        teamAddressTwo.transfer(msg.value.mul(4).div(100));
        teamAddressThree.transfer(msg.value.mul(2).div(100));
        address(JPContract).transfer(msg.value.mul(90).div(100));
    }
}

contract Bears is Team {
    constructor(address payable _jackPotAddress, address payable _CBCTokenAddress) public {
        JPContract = JackPot(_jackPotAddress);
        JPContract.setBearsAddress(address(this));
        CBCTokenContract = CBCToken(_CBCTokenAddress);
        CBCTokenContract.approve(_jackPotAddress, 9999999999999999999000000000000000000);
    }
}

contract Bulls is Team {
    constructor(address payable _jackPotAddress, address payable _CBCTokenAddress) public {
        JPContract = JackPot(_jackPotAddress);
        JPContract.setBullsAddress(address(this));
        CBCTokenContract = CBCToken(_CBCTokenAddress);
        CBCTokenContract.approve(_jackPotAddress, 9999999999999999999000000000000000000);
    }
}

pragma solidity ^0.5.1;

contract JackPot {

    using SafeMath for uint256;

    mapping (address => uint256) public depositBears;
    mapping (address => uint256) public depositBulls;
    uint256 public currentDeadline;
    uint256 public lastDeadline = 1546257600;
    uint256 public countOfBears;
    uint256 public countOfBulls;
    uint256 public totalSupplyOfBulls;
    uint256 public totalSupplyOfBears;
    uint256 public totalCBCSupplyOfBulls;
    uint256 public totalCBCSupplyOfBears;
    uint256 public probabilityOfBulls;
    uint256 public probabilityOfBears;
    address public lastHero;
    address public lastHeroHistory;
    uint256 public jackPot;
    uint256 public winner;
    bool public finished = false;

    Bears public BearsContract;
    Bulls public BullsContract;
    CBCToken public CBCTokenContract;

    constructor() public {
        currentDeadline = block.timestamp + 60 * 60 * 24 * 3;
    }

     
    function setCBCTokenAddress(address _CBCTokenAddress) public {
        require(address(CBCTokenContract) == address(0x0));
        CBCTokenContract = CBCToken(_CBCTokenAddress);
    }

     
    function setBearsAddress(address payable _bearsAddress) external {
        require(address(BearsContract) == address(0x0));
        BearsContract = Bears(_bearsAddress);
    }

     
    function setBullsAddress(address payable _bullsAddress) external {
        require(address(BullsContract) == address(0x0));
        BullsContract = Bulls(_bullsAddress);
    }

    function getNow() view public returns(uint){
        return block.timestamp;
    }

    function getState() view public returns(bool) {
        if (block.timestamp > currentDeadline) {
            return false;
        }
        return true;
    }

    function setInfo(address _lastHero, uint256 _deposit) public {
        require(address(BearsContract) == msg.sender || address(BullsContract) == msg.sender);

        if (address(BearsContract) == msg.sender) {
            require(depositBulls[_lastHero] == 0, "You are already in bulls team");
            if (depositBears[_lastHero] == 0)
                countOfBears++;
            totalSupplyOfBears = totalSupplyOfBears.add(_deposit.mul(90).div(100));
            depositBears[_lastHero] = depositBears[_lastHero].add(_deposit.mul(90).div(100));
        }

        if (address(BullsContract) == msg.sender) {
            require(depositBears[_lastHero] == 0, "You are already in bears team");
            if (depositBulls[_lastHero] == 0)
                countOfBulls++;
            totalSupplyOfBulls = totalSupplyOfBulls.add(_deposit.mul(90).div(100));
            depositBulls[_lastHero] = depositBulls[_lastHero].add(_deposit.mul(90).div(100));
        }

        lastHero = _lastHero;

        if (currentDeadline.add(120) <= lastDeadline) {
            currentDeadline = currentDeadline.add(120);
        } else {
            currentDeadline = lastDeadline;
        }

        jackPot = (address(this).balance.add(_deposit)).mul(10).div(100);

        calculateProbability();
    }

    function calculateProbability() public {
        require(winner == 0 && getState());

        totalCBCSupplyOfBulls = CBCTokenContract.balanceOf(address(BullsContract));
        totalCBCSupplyOfBears = CBCTokenContract.balanceOf(address(BearsContract));
        uint256 percent = (totalSupplyOfBulls.add(totalSupplyOfBears)).div(100);

        if (totalCBCSupplyOfBulls < 1 ether) {
            totalCBCSupplyOfBulls = 0;
        }

        if (totalCBCSupplyOfBears < 1 ether) {
            totalCBCSupplyOfBears = 0;
        }

        if (totalCBCSupplyOfBulls <= totalCBCSupplyOfBears) {
            uint256 difference = totalCBCSupplyOfBears.sub(totalCBCSupplyOfBulls).div(0.01 ether);
            probabilityOfBears = totalSupplyOfBears.mul(100).div(percent).add(difference);

            if (probabilityOfBears > 8000) {
                probabilityOfBears = 8000;
            }
            if (probabilityOfBears < 2000) {
                probabilityOfBears = 2000;
            }
            probabilityOfBulls = 10000 - probabilityOfBears;
        } else {
            uint256 difference = totalCBCSupplyOfBulls.sub(totalCBCSupplyOfBears).div(0.01 ether);
            probabilityOfBulls = totalSupplyOfBulls.mul(100).div(percent).add(difference);

            if (probabilityOfBulls > 8000) {
                probabilityOfBulls = 8000;
            }
            if (probabilityOfBulls < 2000) {
                probabilityOfBulls = 2000;
            }
            probabilityOfBears = 10000 - probabilityOfBulls;
        }

        totalCBCSupplyOfBulls = CBCTokenContract.balanceOf(address(BullsContract));
        totalCBCSupplyOfBears = CBCTokenContract.balanceOf(address(BearsContract));
    }

    function getWinners() public {
        require(winner == 0 && !getState());

        uint256 seed1 = address(this).balance;
        uint256 seed2 = totalSupplyOfBulls;
        uint256 seed3 = totalSupplyOfBears;
        uint256 seed4 = totalCBCSupplyOfBulls;
        uint256 seed5 = totalCBCSupplyOfBulls;
        uint256 seed6 = block.difficulty;
        uint256 seed7 = block.timestamp;

        bytes32 randomHash = keccak256(abi.encodePacked(seed1, seed2, seed3, seed4, seed5, seed6, seed7));
        uint randomNumber = uint(randomHash);

        if (randomNumber == 0){
            randomNumber = 1;
        }

        uint winningNumber = randomNumber % 10000;

        if (1 <= winningNumber && winningNumber <= probabilityOfBears){
            winner = 1;
        }

        if (probabilityOfBears < winningNumber && winningNumber <= 10000){
            winner = 2;
        }
    }

     
    function () external payable {
        if (msg.value == 0 &&  !getState() && winner > 0){
            require(depositBears[msg.sender] > 0 || depositBulls[msg.sender] > 0);

            uint payout = 0;
            uint payoutCBC = 0;

            if (winner == 1 && depositBears[msg.sender] > 0) {
                payout = calculateETHPrize(msg.sender);
            }
            if (winner == 2 && depositBulls[msg.sender] > 0) {
                payout = calculateETHPrize(msg.sender);
            }

            if (payout > 0) {
                depositBears[msg.sender] = 0;
                depositBulls[msg.sender] = 0;
                msg.sender.transfer(payout);
            }

            if ((winner == 1 && depositBears[msg.sender] == 0) || (winner == 2 && depositBulls[msg.sender] == 0)) {
                payoutCBC = calculateCBCPrize(msg.sender);
                if (CBCTokenContract.balanceOf(address(BullsContract)) > 0)
                    CBCTokenContract.transferFrom(
                        address(BullsContract),
                        address(this),
                        CBCTokenContract.balanceOf(address(BullsContract))
                    );
                if (CBCTokenContract.balanceOf(address(BearsContract)) > 0)
                    CBCTokenContract.transferFrom(
                        address(BearsContract),
                        address(this),
                        CBCTokenContract.balanceOf(address(BearsContract))
                    );
                CBCTokenContract.transfer(msg.sender, payoutCBC);
            }

            if (msg.sender == lastHero) {
                lastHeroHistory = lastHero;
                lastHero = address(0x0);
                msg.sender.transfer(jackPot);
            }
        }
    }

    function calculateETHPrize(address participant) public view returns(uint) {

        uint payout = 0;
        uint256 totalSupply = (totalSupplyOfBears.add(totalSupplyOfBulls));

        if (depositBears[participant] > 0) {
            payout = totalSupply.mul(depositBears[participant]).div(totalSupplyOfBears);
        }

        if (depositBulls[participant] > 0) {
            payout = totalSupply.mul(depositBulls[participant]).div(totalSupplyOfBulls);
        }

        return payout;
    }

    function calculateCBCPrize(address participant) public view returns(uint) {

        uint payout = 0;
        uint totalSupply = (totalCBCSupplyOfBears.add(totalCBCSupplyOfBulls)).mul(80).div(100);

        if (depositBears[participant] > 0) {
            payout = totalSupply.mul(depositBears[participant]).div(totalSupplyOfBears);
        }

        if (depositBulls[participant] > 0) {
            payout = totalSupply.mul(depositBulls[participant]).div(totalSupplyOfBulls);
        }

        return payout;
    }


}
pragma solidity ^0.5.1;


 
contract Ownable {
    address public owner;


     
    constructor() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}



 
contract Authorizable {

    address[] authorizers;
    mapping(address => uint) authorizerIndex;

     
    modifier onlyAuthorized {
        require(isAuthorized(msg.sender));
        _;
    }

     
    constructor() public {
        authorizers.length = 2;
        authorizers[1] = msg.sender;
        authorizerIndex[msg.sender] = 1;
    }

     
    function getAuthorizer(uint authorizerIndex) external view returns(address) {
        return address(authorizers[authorizerIndex + 1]);
    }

     
    function isAuthorized(address _addr) public view returns(bool) {
        return authorizerIndex[_addr] > 0;
    }

     
    function addAuthorized(address _addr) external onlyAuthorized {
        authorizerIndex[_addr] = authorizers.length;
        authorizers.length++;
        authorizers[authorizers.length - 1] = _addr;
    }

}

 
contract ExchangeRate is Ownable {

    event RateUpdated(uint timestamp, bytes32 symbol, uint rate);

    mapping(bytes32 => uint) public rates;

     
    function updateRate(string memory _symbol, uint _rate) public onlyOwner {
        rates[keccak256(abi.encodePacked(_symbol))] = _rate;
        emit RateUpdated(now, keccak256(bytes(_symbol)), _rate);
    }

     
    function updateRates(uint[] memory data) public onlyOwner {
        require (data.length % 2 <= 0);
        uint i = 0;
        while (i < data.length / 2) {
            bytes32 symbol = bytes32(data[i * 2]);
            uint rate = data[i * 2 + 1];
            rates[symbol] = rate;
            emit RateUpdated(now, symbol, rate);
            i++;
        }
    }

     
    function getRate(string memory _symbol) public view returns(uint) {
        return rates[keccak256(abi.encodePacked(_symbol))];
    }

}

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


 
contract ERC20Basic {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}




 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) view public returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}




 
contract BasicToken is ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) balances;

     
    modifier onlyPayloadSize(uint size) {
        require (size + 4 <= msg.data.length);
        _;
    }

     
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
    }

     
    function balanceOf(address _owner) view public returns (uint balance) {
        return balances[_owner];
    }

}




 
contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) allowed;


     
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
        uint256 _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
    }

     
    function approve(address _spender, uint _value) public {

         
         
         
         
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

     
    function allowance(address _owner, address _spender) view public returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}


 

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint value);
    event MintFinished();
    event Burn(address indexed burner, uint256 value);

    bool public mintingFinished = false;
    uint public totalSupply = 0;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint _amount) onlyOwner canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }


     
    function burn(address _who, uint256 _value) onlyOwner public {
        _burn(_who, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
         
         

        balances[_who] = balances[_who].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}


 
contract CBCToken is MintableToken {

    string public name = "Crypto Boss Coin";
    string public symbol = "CBC";
    uint public decimals = 18;

    bool public tradingStarted = false;
     
    modifier hasStartedTrading() {
        require(tradingStarted);
        _;
    }


     
    function startTrading() onlyOwner public {
        tradingStarted = true;
    }

     
    function transfer(address _to, uint _value) hasStartedTrading public {
        super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value) hasStartedTrading public{
        super.transferFrom(_from, _to, _value);
    }

}

 
contract MainSale is Ownable, Authorizable {
    using SafeMath for uint;
    event TokenSold(address recipient, uint ether_amount, uint pay_amount, uint exchangerate);
    event AuthorizedCreate(address recipient, uint pay_amount);
    event AuthorizedBurn(address receiver, uint value);
    event AuthorizedStartTrading();
    event MainSaleClosed();
    CBCToken public token = new CBCToken();

    address payable public multisigVault;

    uint hardcap = 100000000000000 ether;
    ExchangeRate public exchangeRate;

    uint public altDeposits = 0;
    uint public start = 1525996800;

     
    modifier saleIsOn() {
        require(now > start && now < start + 28 days);
        _;
    }

     
    modifier isUnderHardCap() {
        require(multisigVault.balance + altDeposits <= hardcap);
        _;
    }

     
    function createTokens(address recipient) public isUnderHardCap saleIsOn payable {
        uint rate = exchangeRate.getRate("ETH");
        uint tokens = rate.mul(msg.value).div(1 ether);
        token.mint(recipient, tokens);
        require(multisigVault.send(msg.value));
        emit TokenSold(recipient, msg.value, tokens, rate);
    }

     
    function setAltDeposit(uint totalAltDeposits) public onlyOwner {
        altDeposits = totalAltDeposits;
    }

     
    function authorizedCreateTokens(address recipient, uint tokens) public onlyAuthorized {
        token.mint(recipient, tokens);
        emit AuthorizedCreate(recipient, tokens);
    }

    function authorizedStartTrading() public onlyAuthorized {
        token.startTrading();
        emit AuthorizedStartTrading();
    }

     
    function authorizedBurnTokens(address receiver, uint value) public onlyAuthorized {
        token.burn(receiver, value);
        emit AuthorizedBurn(receiver, value);
    }

     
    function setHardCap(uint _hardcap) public onlyOwner {
        hardcap = _hardcap;
    }

     
    function setStart(uint _start) public onlyOwner {
        start = _start;
    }

     
    function setMultisigVault(address payable _multisigVault) public onlyOwner {
        if (_multisigVault != address(0)) {
            multisigVault = _multisigVault;
        }
    }

     
    function setExchangeRate(address _exchangeRate) public onlyOwner {
        exchangeRate = ExchangeRate(_exchangeRate);
    }

     
    function finishMinting() public onlyOwner {
        uint issuedTokenSupply = token.totalSupply();
        uint restrictedTokens = issuedTokenSupply.mul(49).div(51);
        token.mint(multisigVault, restrictedTokens);
        token.finishMinting();
        token.transferOwnership(owner);
        emit MainSaleClosed();
    }

     
    function retrieveTokens(address _token) public onlyOwner {
        ERC20 token = ERC20(_token);
        token.transfer(multisigVault, token.balanceOf(address(this)));
    }

     
    function() external payable {
        createTokens(msg.sender);
    }

}