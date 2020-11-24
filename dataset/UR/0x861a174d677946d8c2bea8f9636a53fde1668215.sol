 

pragma solidity ^0.4.24;

 
contract InsuranceFund {
    using SafeMath for uint256;

     
    struct Investor {
        uint256 deposit;
        uint256 withdrawals;
        bool insured;
    }
    mapping (address => Investor) public investors;
    uint public countOfInvestors;

    bool public startOfPayments = false;
    uint256 public totalSupply;

    uint256 public totalNotReceived;
    address public SCBAddress;

    SmartContractBank SCBContract;

    event Paid(address investor, uint256 amount, uint256  notRecieve, uint256  partOfNotReceived);
    event SetInfo(address investor, uint256  notRecieve, uint256 deposit, uint256 withdrawals);

     
    modifier onlySCB() {
        require(msg.sender == SCBAddress, "access denied");
        _;
    }

     
    function setSCBAddress(address _SCBAddress) public {
        require(SCBAddress == address(0x0));
        SCBAddress = _SCBAddress;
        SCBContract = SmartContractBank(SCBAddress);
    }

     
    function privateSetInfo(address _address, uint256 deposit, uint256 withdrawals) private{
        if (!startOfPayments) {
            Investor storage investor = investors[_address];

            if (investor.deposit != deposit){
                totalNotReceived = totalNotReceived.add(deposit.sub(investor.deposit));
                investor.deposit = deposit;
            }

            if (investor.withdrawals != withdrawals){
                uint256 different;
                if (deposit <= withdrawals){
                    different = deposit.sub(withdrawals);
                    if (totalNotReceived >= different)
                        totalNotReceived = totalNotReceived.sub(different);
                    else
                        totalNotReceived = 0;
                } else {
                    different = withdrawals.sub(investor.withdrawals);
                    if (totalNotReceived >= different)
                        totalNotReceived = totalNotReceived.sub(different);
                    else
                        totalNotReceived = 0;
                }
                investor.withdrawals = withdrawals;
            }

            emit SetInfo(_address, totalNotReceived, investor.deposit, investor.withdrawals);
        }
    }

     
    function setInfo(address _address, uint256 deposit, uint256 withdrawals) public onlySCB {
        privateSetInfo(_address, deposit, withdrawals);
    }

     
    function deleteInsured(address _address) public onlySCB {
        Investor storage investor = investors[_address];
        investor.deposit = 0;
        investor.withdrawals = 0;
        investor.insured = false;
        countOfInvestors--;
    }

     
    function beginOfPayments() public {
        require(address(SCBAddress).balance < 0.1 ether && !startOfPayments);
        startOfPayments = true;
        totalSupply = address(this).balance;
    }

     
    function () external payable {
        Investor storage investor = investors[msg.sender];
        if (msg.value > 0 ether){
            require(!startOfPayments);
            if (msg.sender != SCBAddress && msg.value >= 0.1 ether) {
                uint256 deposit;
                uint256 withdrawals;
                (deposit, withdrawals, investor.insured) = SCBContract.setInsured(msg.sender);
                countOfInvestors++;
                privateSetInfo(msg.sender, deposit, withdrawals);
            }
        } else if (msg.value == 0){
            uint256 notReceived = investor.deposit.sub(investor.withdrawals);
            uint256 partOfNotReceived = notReceived.mul(100).div(totalNotReceived);
            uint256 payAmount = totalSupply.div(100).mul(partOfNotReceived);
            require(startOfPayments && investor.insured && notReceived > 0);
            investor.insured = false;
            msg.sender.transfer(payAmount);
            emit Paid(msg.sender, payAmount, notReceived, partOfNotReceived);
        }
    }
}

 
contract SmartContractBank {
    using SafeMath for uint256;
    struct Investor {
        uint256 deposit;
        uint256 paymentTime;
        uint256 withdrawals;
        bool increasedPercent;
        bool insured;
    }
    uint public countOfInvestors;
    mapping (address => Investor) public investors;

    uint256 public minimum = 0.01 ether;
    uint step = 5 minutes;
    uint ownerPercent = 4;
    uint promotionPercent = 8;
    uint insurancePercent = 2;
    bool public closed = false;

    address public ownerAddressOne = 0xaB5007407d8A686B9198079816ebBaaa2912ecC1;
    address public ownerAddressTwo = 0x4A5b00cDDAeE928B8De7a7939545f372d6727C06;
    address public promotionAddress = 0x3878E2231f7CA61c0c1D0Aa3e6962d7D23Df1B3b;
    address public insuranceFundAddress;
    address public CBCTokenAddress = 0x790bFaCaE71576107C068f494c8A6302aea640cb;
    address public MainSaleAddress = 0x369fc7de8aee87a167244eb10b87eb3005780872;

    InsuranceFund IFContract;
    CBCToken CBCTokenContract = CBCToken(CBCTokenAddress);
    MainSale MainSaleContract = MainSale(MainSaleAddress);
    
    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount);
    event UserDelete(address investor);

     
    modifier onlyIF() {
        require(insuranceFundAddress == msg.sender, "access denied");
        _;
    }

     
    function setInsuranceFundAddress(address _insuranceFundAddress) public{
        require(insuranceFundAddress == address(0x0));
        insuranceFundAddress = _insuranceFundAddress;
        IFContract = InsuranceFund(insuranceFundAddress);
    }

     
    function setInsured(address _address) public onlyIF returns(uint256, uint256, bool){
        Investor storage investor = investors[_address];
        investor.insured = true;
        return (investor.deposit, investor.withdrawals, investor.insured);
    }

     
    function closeEntrance() public {
        require(address(this).balance < 0.1 ether && !closed);
        closed = true;
    }

     
    function getPhasePercent() view public returns (uint){
        Investor storage investor = investors[msg.sender];
        uint contractBalance = address(this).balance;
        uint percent;
        if (contractBalance < 100 ether) {
            percent = 40;
        }
        if (contractBalance >= 100 ether && contractBalance < 600 ether) {
            percent = 20;
        }
        if (contractBalance >= 600 ether && contractBalance < 1000 ether) {
            percent = 10;
        }
        if (contractBalance >= 1000 ether && contractBalance < 3000 ether) {
            percent = 9;
        }
        if (contractBalance >= 3000 ether && contractBalance < 5000 ether) {
            percent = 8;
        }
        if (contractBalance >= 5000 ether) {
            percent = 7;
        }

        if (investor.increasedPercent){
            percent = percent.add(5);
        }

        return percent;
    }

     
    function allocation() private{
        ownerAddressOne.transfer(msg.value.mul(ownerPercent.div(2)).div(100));
        ownerAddressTwo.transfer(msg.value.mul(ownerPercent.div(2)).div(100));
        promotionAddress.transfer(msg.value.mul(promotionPercent).div(100));
        insuranceFundAddress.transfer(msg.value.mul(insurancePercent).div(100));
    }

     
    function getUserBalance(address _address) view public returns (uint256) {
        Investor storage investor = investors[_address];
        uint percent = getPhasePercent();
        uint256 differentTime = now.sub(investor.paymentTime).div(step);
        uint256 differentPercent = investor.deposit.mul(percent).div(1000);
        uint256 payout = differentPercent.mul(differentTime).div(288);

        return payout;
    }

     
    function withdraw() private {
        Investor storage investor = investors[msg.sender];
        uint256 balance = getUserBalance(msg.sender);
        if (investor.deposit > 0 && address(this).balance > balance && balance > 0) {
            uint256 tempWithdrawals = investor.withdrawals;

            investor.withdrawals = investor.withdrawals.add(balance);
            investor.paymentTime = now;

            if (investor.withdrawals >= investor.deposit.mul(2)){
                investor.deposit = 0;
                investor.paymentTime = 0;
                investor.withdrawals = 0;
                investor.increasedPercent = false;
                investor.insured = false;
                countOfInvestors--;
                if (investor.insured)
                    IFContract.deleteInsured(msg.sender);
                emit UserDelete(msg.sender);
            } else {
                if (investor.insured && tempWithdrawals < investor.deposit){
                    IFContract.setInfo(msg.sender, investor.deposit, investor.withdrawals);
                }
            }
            msg.sender.transfer(balance);
            emit Withdraw(msg.sender, balance);
        }

    }

     
    function increasePercent() public {
        Investor storage investor = investors[msg.sender];
        if (CBCTokenContract.balanceOf(msg.sender) >= 10 ether){
            MainSaleContract.authorizedBurnTokens(msg.sender, 10 ether);
            investor.increasedPercent = true;
        }
    }

     
    function () external payable {
        require(!closed);
        Investor storage investor = investors[msg.sender];
        if (msg.value >= minimum){
        
            withdraw();

            if (investor.deposit == 0){
                countOfInvestors++;
            }

            investor.deposit = investor.deposit.add(msg.value);
            investor.paymentTime = now;

            if (investor.insured){
                IFContract.setInfo(msg.sender, investor.deposit, investor.withdrawals);
            }
            allocation();
            emit Invest(msg.sender, msg.value);
        } else if (msg.value == 0.0001 ether) {
            increasePercent();
        } else {
            withdraw();
        }
    }
}


 
contract Ownable {
    address public owner;


     
    function Ownable() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner {
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

     
    function Authorizable() public {
        authorizers.length = 2;
        authorizers[1] = msg.sender;
        authorizerIndex[msg.sender] = 1;
    }

     
    function getAuthorizer(uint authorizerIndex) external constant returns(address) {
        return address(authorizers[authorizerIndex + 1]);
    }

     
    function isAuthorized(address _addr) public constant returns(bool) {
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

     
    function updateRate(string _symbol, uint _rate) public onlyOwner {
        rates[keccak256(_symbol)] = _rate;
        RateUpdated(now, keccak256(_symbol), _rate);
    }

     
    function updateRates(uint[] data) public onlyOwner {
        require (data.length % 2 <= 0);
        uint i = 0;
        while (i < data.length / 2) {
            bytes32 symbol = bytes32(data[i * 2]);
            uint rate = data[i * 2 + 1];
            rates[symbol] = rate;
            RateUpdated(now, symbol, rate);
            i++;
        }
    }

     
    function getRate(string _symbol) public constant returns(uint) {
        return rates[keccak256(_symbol)];
    }

}

 
library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }

    function assert(bool assertion) internal {
        require(assertion);
    }
}


 
contract ERC20Basic {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}




 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint);
    function transferFrom(address from, address to, uint value);
    function approve(address spender, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}




 
contract BasicToken is ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) balances;

     
    modifier onlyPayloadSize(uint size) {
        require (size + 4 <= msg.data.length);
        _;
    }

     
    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }

     
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

}




 
contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) allowed;


     
    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

     
    function approve(address _spender, uint _value) {

         
         
         
         
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

     
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
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

     
    function mint(address _to, uint _amount) onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }


     
    function burn(address _who, uint256 _value) onlyOwner public {
        _burn(_who, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
         
         

        balances[_who] = balances[_who].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(_who, _value);
        Transfer(_who, address(0), _value);
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


     
    function startTrading() onlyOwner {
        tradingStarted = true;
    }

     
    function transfer(address _to, uint _value) hasStartedTrading {
        super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value) hasStartedTrading {
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

    address public multisigVault;

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
        TokenSold(recipient, msg.value, tokens, rate);
    }

     
    function setAltDeposit(uint totalAltDeposits) public onlyOwner {
        altDeposits = totalAltDeposits;
    }

     
    function authorizedCreateTokens(address recipient, uint tokens) public onlyAuthorized {
        token.mint(recipient, tokens);
        AuthorizedCreate(recipient, tokens);
    }

    function authorizedStartTrading() public onlyAuthorized {
        token.startTrading();
        AuthorizedStartTrading();
    }

     
    function authorizedBurnTokens(address receiver, uint value) public onlyAuthorized {
        token.burn(receiver, value);
        AuthorizedBurn(receiver, value);
    }

     
    function setHardCap(uint _hardcap) public onlyOwner {
        hardcap = _hardcap;
    }

     
    function setStart(uint _start) public onlyOwner {
        start = _start;
    }

     
    function setMultisigVault(address _multisigVault) public onlyOwner {
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
        MainSaleClosed();
    }

     
    function retrieveTokens(address _token) public onlyOwner {
        ERC20 token = ERC20(_token);
        token.transfer(multisigVault, token.balanceOf(this));
    }

     
    function() external payable {
        createTokens(msg.sender);
    }

}