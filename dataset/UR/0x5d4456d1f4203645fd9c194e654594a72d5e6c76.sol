 

pragma solidity 0.5.6;



 


 

 
 
 
 
contract allowanceRecipient {
    function receiveApproval(address _from, uint256 _value, address _inContract, bytes memory _extraData) public returns (bool success);
}


 
 
contract tokenRecipient {
    function tokenFallback(address _from, uint256 _value, bytes memory _extraData) public returns (bool success);
}


contract DEEX {

     

     

     

     
     
    string public name = "deex";

     
     
    string public symbol = "deex";

     
     
    uint8 public decimals = 0;

     
     
     
    uint256 public totalSupply;

     
     
    mapping (address => uint256) public balanceOf;

     
     
    mapping (address => mapping (address => uint256)) public allowance;

     

    uint256 public salesCounter = 0;

    uint256 public maxSalesAllowed;

    bool private transfersBetweenSalesAllowed;

     
    uint256 public tokenPriceInWei = 0;

    uint256 public saleStartUnixTime = 0;  
    uint256 public saleEndUnixTime = 0;   

     
    address public owner;

     
    address public priceSetter;

     
    uint256 private priceMaxWei = 0;
     
    uint256 private priceMinWei = 0;

     
    mapping (address => bool) public isPreferredTokensAccount;

    bool public contractInitialized = false;


     
     
     
    constructor () public {
        owner = msg.sender;

         
         
        maxSalesAllowed = 2;
         
        transfersBetweenSalesAllowed = true;
    }


    function initContract(address team, address advisers, address bounty) public onlyBy(owner) returns (bool){

        require(contractInitialized == false);
        contractInitialized = true;

        priceSetter = msg.sender;

        totalSupply = 100000000;

         
        balanceOf[address(this)] = 75000000;

         
        balanceOf[team] = balanceOf[team] + 15000000;
        isPreferredTokensAccount[team] = true;

         
        balanceOf[advisers] = balanceOf[advisers] + 7000000;
        isPreferredTokensAccount[advisers] = true;

         
        balanceOf[bounty] = balanceOf[bounty] + 3000000;
        isPreferredTokensAccount[bounty] = true;

    }

     

     
     

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed _owner, address indexed spender, uint256 value);

     
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

     

    event PriceChanged(uint256 indexed newTokenPriceInWei);

    event SaleStarted(uint256 startUnixTime, uint256 endUnixTime, uint256 indexed saleNumber);

    event NewTokensSold(uint256 numberOfTokens, address indexed purchasedBy, uint256 indexed priceInWei);

    event Withdrawal(address indexed to, uint sumInWei);

     
    event DataSentToAnotherContract(address indexed _from, address indexed _toContract, bytes _extraData);

     

     
    modifier onlyBy(address _account){
        require(msg.sender == _account);

        _;
    }

     
     

     
    function transfer(address _to, uint256 _value) public returns (bool){
        return transferFrom(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){

         
         

        bool saleFinished = saleIsFinished();
        require(saleFinished || msg.sender == owner || isPreferredTokensAccount[msg.sender]);

         
         
        require(transfersBetweenSalesAllowed || salesCounter == maxSalesAllowed || msg.sender == owner || isPreferredTokensAccount[msg.sender]);

         
        require(_value >= 0);

         
        require(msg.sender == _from || _value <= allowance[_from][msg.sender]);

         
        require(_value <= balanceOf[_from]);

         
        balanceOf[_from] = balanceOf[_from] - _value;
         
         
        balanceOf[_to] = balanceOf[_to] + _value;

         
        if (_from != msg.sender) {
            allowance[_from][msg.sender] = allowance[_from][msg.sender] - _value;
        }

         
        emit Transfer(_from, _to, _value);

        return true;
    }

     
     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success){

        require(_value >= 0);

        allowance[msg.sender][_spender] = _value;

         
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

     

     
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {

        approve(_spender, _value);

         
        allowanceRecipient spender = allowanceRecipient(_spender);

         
         
         
        if (spender.receiveApproval(msg.sender, _value, address(this), _extraData)) {
            emit DataSentToAnotherContract(msg.sender, _spender, _extraData);
            return true;
        }
        else return false;
    }

    function approveAllAndCall(address _spender, bytes memory _extraData) public returns (bool success) {
        return approveAndCall(_spender, balanceOf[msg.sender], _extraData);
    }

     
    function transferAndCall(address _to, uint256 _value, bytes memory _extraData) public returns (bool success){

        transferFrom(msg.sender, _to, _value);

        tokenRecipient receiver = tokenRecipient(_to);

        if (receiver.tokenFallback(msg.sender, _value, _extraData)) {
            emit DataSentToAnotherContract(msg.sender, _to, _extraData);
            return true;
        }
        else return false;
    }

     
    function transferAllAndCall(address _to, bytes memory _extraData) public returns (bool success){
        return transferAndCall(_to, balanceOf[msg.sender], _extraData);
    }

     

    function changeOwner(address _newOwner) public onlyBy(owner) returns (bool success){
         
        require(_newOwner != address(0));

        address oldOwner = owner;
        owner = _newOwner;

        emit OwnerChanged(oldOwner, _newOwner);

        return true;
    }

     

     

    function startSale(uint256 _startUnixTime, uint256 _endUnixTime) public onlyBy(owner) returns (bool success){

        require(balanceOf[address(this)] > 0);
        require(salesCounter < maxSalesAllowed);

         
         
         
        require(
            (saleStartUnixTime == 0 && saleEndUnixTime == 0) || saleIsFinished()
        );
         
        require(_startUnixTime > now && _endUnixTime > now);
         
        require(_endUnixTime - _startUnixTime > 0);

        saleStartUnixTime = _startUnixTime;
        saleEndUnixTime = _endUnixTime;
        salesCounter = salesCounter + 1;

        emit SaleStarted(_startUnixTime, _endUnixTime, salesCounter);

        return true;
    }

    function saleIsRunning() public view returns (bool){

        if (balanceOf[address(this)] == 0) {
            return false;
        }

        if (saleStartUnixTime == 0 && saleEndUnixTime == 0) {
            return false;
        }

        if (now > saleStartUnixTime && now < saleEndUnixTime) {
            return true;
        }

        return false;
    }

    function saleIsFinished() public view returns (bool){

        if (balanceOf[address(this)] == 0) {
            return true;
        }

        else if (
            (saleStartUnixTime > 0 && saleEndUnixTime > 0)
            && now > saleEndUnixTime) {

            return true;
        }

         
        return true;
    }

    function changePriceSetter(address _priceSetter) public onlyBy(owner) returns (bool success) {
        priceSetter = _priceSetter;
        return true;
    }

    function setMinMaxPriceInWei(uint256 _priceMinWei, uint256 _priceMaxWei) public onlyBy(owner) returns (bool success){
        require(_priceMinWei >= 0 && _priceMaxWei >= 0);
        priceMinWei = _priceMinWei;
        priceMaxWei = _priceMaxWei;
        return true;
    }


    function setTokenPriceInWei(uint256 _priceInWei) public onlyBy(priceSetter) returns (bool success){

        require(_priceInWei >= 0);

         
        if (priceMinWei != 0 && _priceInWei < priceMinWei) {
            tokenPriceInWei = priceMinWei;
        }
        else if (priceMaxWei != 0 && _priceInWei > priceMaxWei) {
            tokenPriceInWei = priceMaxWei;
        }
        else {
            tokenPriceInWei = _priceInWei;
        }

        emit PriceChanged(tokenPriceInWei);

        return true;
    }

     
     
     
     
     
    function() external payable {
        buyTokens();
    }

     
    function buyTokens() public payable returns (bool success){

        if (saleIsRunning() && tokenPriceInWei > 0) {

            uint256 numberOfTokens = msg.value / tokenPriceInWei;

            if (numberOfTokens <= balanceOf[address(this)]) {

                balanceOf[msg.sender] = balanceOf[msg.sender] + numberOfTokens;
                balanceOf[address(this)] = balanceOf[address(this)] - numberOfTokens;

                emit NewTokensSold(numberOfTokens, msg.sender, tokenPriceInWei);

                return true;
            }
            else {
                 
                revert();
            }
        }
        else {
             
            revert();
        }
    }

     
    function withdrawAllToOwner() public onlyBy(owner) returns (bool) {

         
        require(saleIsFinished());
        uint256 sumInWei = address(this).balance;

        if (
         
            !msg.sender.send(address(this).balance)
        ) {
            return false;
        }
        else {
             
            emit Withdrawal(msg.sender, sumInWei);
            return true;
        }
    }

     

     
     
     
    mapping (bytes32 => bool) private isReferrer;

    uint256 private referralBonus = 0;

    uint256 private referrerBonus = 0;
     
    mapping (bytes32 => uint256) public referrerBalanceOf;

    mapping (bytes32 => uint) public referrerLinkedSales;

    function addReferrer(bytes32 _referrer) public onlyBy(owner) returns (bool success){
        isReferrer[_referrer] = true;
        return true;
    }

    function removeReferrer(bytes32 _referrer) public onlyBy(owner) returns (bool success){
        isReferrer[_referrer] = false;
        return true;
    }

     
    function setReferralBonuses(uint256 _referralBonus, uint256 _referrerBonus) public onlyBy(owner) returns (bool success){
        require(_referralBonus > 0 && _referrerBonus > 0);
        referralBonus = _referralBonus;
        referrerBonus = _referrerBonus;
        return true;
    }

    function buyTokensWithReferrerAddress(address _referrer) public payable returns (bool success){

        bytes32 referrer = keccak256(abi.encodePacked(_referrer));

        if (saleIsRunning() && tokenPriceInWei > 0) {

            if (isReferrer[referrer]) {

                uint256 numberOfTokens = msg.value / tokenPriceInWei;

                if (numberOfTokens <= balanceOf[address(this)]) {

                    referrerLinkedSales[referrer] = referrerLinkedSales[referrer] + numberOfTokens;

                    uint256 referralBonusTokens = (numberOfTokens * (100 + referralBonus) / 100) - numberOfTokens;
                    uint256 referrerBonusTokens = (numberOfTokens * (100 + referrerBonus) / 100) - numberOfTokens;

                    balanceOf[address(this)] = balanceOf[address(this)] - numberOfTokens - referralBonusTokens - referrerBonusTokens;

                    balanceOf[msg.sender] = balanceOf[msg.sender] + (numberOfTokens + referralBonusTokens);

                    referrerBalanceOf[referrer] = referrerBalanceOf[referrer] + referrerBonusTokens;

                    emit NewTokensSold(numberOfTokens + referralBonusTokens, msg.sender, tokenPriceInWei);

                    return true;
                }
                else {
                     
                    revert();
                }
            }
            else {
                 
                buyTokens();
            }
        }
        else {
             
            revert();
        }
    }

    event ReferrerBonusTokensTaken(address referrer, uint256 bonusTokensValue);

    function getReferrerBonusTokens() public returns (bool success){
        require(saleIsFinished());
        uint256 bonusTokens = referrerBalanceOf[keccak256(abi.encodePacked(msg.sender))];
        balanceOf[msg.sender] = balanceOf[msg.sender] + bonusTokens;
        emit ReferrerBonusTokensTaken(msg.sender, bonusTokens);
        return true;
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


contract Ownable {
    address payable public owner;
     
    constructor() public {
        owner = msg.sender;
    }
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}


 
contract Bank is Ownable {

    using SafeMath for uint256;

    mapping (uint256 => mapping (address => uint256)) public depositDragons;
    mapping (uint256 => mapping (address => uint256)) public depositHamsters;

    address payable public team = 0x7De1eFb9E5035784FB931433c8a884588929338E;

    uint256 public currentDeadline;
    uint256 public currentRound = 1;
    uint256 public lastDeadline;
    uint256 public defaultCurrentDeadlineInHours = 24;
    uint256 public defaultLastDeadlineInHours = 48;
    uint256 public countOfDragons;
    uint256 public countOfHamsters;
    uint256 public totalSupplyOfHamsters;
    uint256 public totalSupplyOfDragons;
    uint256 public totalDeexSupplyOfHamsters;
    uint256 public totalDeexSupplyOfDragons;
    uint256 public probabilityOfHamsters;
    uint256 public probabilityOfDragons;
    address public lastHero;
    address public lastHeroHistory;
    uint256 public jackPot;
    uint256 public winner;
    uint256 public withdrawn;
    uint256 public withdrawnDeex;
    uint256 public remainder;
    uint256 public remainderDeex;
    uint256 public rate = 1;
    uint256 public rateModifier = 0;
    uint256 public tokenReturn;

    uint256 public lastTotalSupplyOfHamsters;
    uint256 public lastTotalSupplyOfDragons;
    uint256 public lastTotalDeexSupplyOfHamsters;
    uint256 public lastTotalDeexSupplyOfDragons;
    uint256 public lastProbabilityOfHamsters;
    uint256 public lastProbabilityOfDragons;
    address public lastRoundHero;
    uint256 public lastJackPot;
    uint256 public lastWinner;
    uint256 public lastBalance;
    uint256 public lastBalanceDeex;
    uint256 public lastCountOfDragons;
    uint256 public lastCountOfHamsters;
    uint256 public lastWithdrawn;
    uint256 public lastWithdrawnDeex;


    bool public finished = false;

    Dragons public DragonsContract;
    Hamsters public HamstersContract;
    DEEX public DEEXContract;

     
    function setRateToken(uint256 _rate, uint256 _rateModifier) public onlyOwner returns(uint256){
        rate = _rate;
        rateModifier = _rateModifier;
    }

     
    function _setRoundTime(uint _currentDeadlineInHours, uint _lastDeadlineInHours) internal {
        defaultCurrentDeadlineInHours = _currentDeadlineInHours;
        defaultLastDeadlineInHours = _lastDeadlineInHours;
        currentDeadline = block.timestamp + 60 * 60 * _currentDeadlineInHours;
        lastDeadline = block.timestamp + 60 * 60 * _lastDeadlineInHours;
    }

     
    function setRoundTime(uint _currentDeadlineInHours, uint _lastDeadlineInHours) public onlyOwner {
        _setRoundTime(_currentDeadlineInHours, _lastDeadlineInHours);
    }


     
    function setDEEXAddress(address payable _DEEXAddress) public {
        require(address(DEEXContract) == address(0x0));
        DEEXContract = DEEX(_DEEXAddress);
    }

     
    function setDragonsAddress(address payable _DragonsAddress) external {
        require(address(DragonsContract) == address(0x0));
        DragonsContract = Dragons(_DragonsAddress);
    }

     
    function setHamstersAddress(address payable _HamstersAddress) external {
        require(address(HamstersContract) == address(0x0));
        HamstersContract = Hamsters(_HamstersAddress);
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
        require(address(DragonsContract) == msg.sender || address(HamstersContract) == msg.sender);

        if (address(DragonsContract) == msg.sender) {
            require(depositHamsters[currentRound][_lastHero] == 0, "You are already in Hamsters team");
            if (depositDragons[currentRound][_lastHero] == 0)
                countOfDragons++;
            totalSupplyOfDragons = totalSupplyOfDragons.add(_deposit.mul(90).div(100));
            depositDragons[currentRound][_lastHero] = depositDragons[currentRound][_lastHero].add(_deposit.mul(90).div(100));
        }

        if (address(HamstersContract) == msg.sender) {
            require(depositDragons[currentRound][_lastHero] == 0, "You are already in Dragons team");
            if (depositHamsters[currentRound][_lastHero] == 0)
                countOfHamsters++;
            totalSupplyOfHamsters = totalSupplyOfHamsters.add(_deposit.mul(90).div(100));
            depositHamsters[currentRound][_lastHero] = depositHamsters[currentRound][_lastHero].add(_deposit.mul(90).div(100));
        }

        lastHero = _lastHero;

        if (currentDeadline.add(120) <= lastDeadline) {
            currentDeadline = currentDeadline.add(120);
        } else {
            currentDeadline = lastDeadline;
        }

        jackPot += _deposit.mul(10).div(100);

        calculateProbability();
    }

    function estimateTokenPercent(uint256 _difference) public view returns(uint256){
        if (rateModifier == 0) {
            return _difference.mul(rate);
        } else {
            return _difference.div(rate);
        }
    }

     
    function calculateProbability() public {
        require(winner == 0 && getState());

        totalDeexSupplyOfHamsters = DEEXContract.balanceOf(address(HamstersContract));
        totalDeexSupplyOfDragons = DEEXContract.balanceOf(address(DragonsContract));
        uint256 percent = (totalSupplyOfHamsters.add(totalSupplyOfDragons)).div(100);

        if (totalDeexSupplyOfHamsters < 1) {
            totalDeexSupplyOfHamsters = 0;
        }

        if (totalDeexSupplyOfDragons < 1) {
            totalDeexSupplyOfDragons = 0;
        }

        if (totalDeexSupplyOfHamsters <= totalDeexSupplyOfDragons) {
            uint256 difference = totalDeexSupplyOfDragons.sub(totalDeexSupplyOfHamsters).mul(100);
            probabilityOfDragons = totalSupplyOfDragons.mul(100).div(percent).add(estimateTokenPercent(difference));
  
            if (probabilityOfDragons > 8000) {
                probabilityOfDragons = 8000;
            }
            if (probabilityOfDragons < 2000) {
                probabilityOfDragons = 2000;
            }
            probabilityOfHamsters = 10000 - probabilityOfDragons;
        } else {
            uint256 difference = totalDeexSupplyOfHamsters.sub(totalDeexSupplyOfDragons).mul(100);
            probabilityOfHamsters = totalSupplyOfHamsters.mul(100).div(percent).add(estimateTokenPercent(difference));

            if (probabilityOfHamsters > 8000) {
                probabilityOfHamsters = 8000;
            }
            if (probabilityOfHamsters < 2000) {
                probabilityOfHamsters = 2000;
            }
            probabilityOfDragons = 10000 - probabilityOfHamsters;
        }

        totalDeexSupplyOfHamsters = DEEXContract.balanceOf(address(HamstersContract));
        totalDeexSupplyOfDragons = DEEXContract.balanceOf(address(DragonsContract));
    }

     
    function getWinners() public {
        require(winner == 0 && !getState());
        uint256 seed1 = address(this).balance;
        uint256 seed2 = totalSupplyOfHamsters;
        uint256 seed3 = totalSupplyOfDragons;
        uint256 seed4 = totalDeexSupplyOfHamsters;
        uint256 seed5 = totalDeexSupplyOfHamsters;
        uint256 seed6 = block.difficulty;
        uint256 seed7 = block.timestamp;

        bytes32 randomHash = keccak256(abi.encodePacked(seed1, seed2, seed3, seed4, seed5, seed6, seed7));
        uint randomNumber = uint(randomHash);

        if (randomNumber == 0){
            randomNumber = 1;
        }

        uint winningNumber = randomNumber % 10000;

        if (1 <= winningNumber && winningNumber <= probabilityOfDragons){
            winner = 1;
        }

        if (probabilityOfDragons < winningNumber && winningNumber <= 10000){
            winner = 2;
        }

        if (DEEXContract.balanceOf(address(HamstersContract)) > 0)
            DEEXContract.transferFrom(
                address(HamstersContract),
                address(this),
                DEEXContract.balanceOf(address(HamstersContract))
            );

        if (DEEXContract.balanceOf(address(DragonsContract)) > 0)
            DEEXContract.transferFrom(
                address(DragonsContract),
                address(this),
                DEEXContract.balanceOf(address(DragonsContract))
            );

        lastTotalSupplyOfHamsters = totalSupplyOfHamsters;
        lastTotalSupplyOfDragons = totalSupplyOfDragons;
        lastTotalDeexSupplyOfDragons = totalDeexSupplyOfDragons;
        lastTotalDeexSupplyOfHamsters = totalDeexSupplyOfHamsters;
        lastRoundHero = lastHero;
        lastJackPot = jackPot;
        lastWinner = winner;
        lastCountOfDragons = countOfDragons;
        lastCountOfHamsters = countOfHamsters;
        lastWithdrawn = withdrawn;
        lastWithdrawnDeex = withdrawnDeex;

        if (lastBalance > lastWithdrawn){
            remainder = lastBalance.sub(lastWithdrawn);
           team.transfer(remainder);
        }

        lastBalance = lastTotalSupplyOfDragons.add(lastTotalSupplyOfHamsters).add(lastJackPot);

        if (lastBalanceDeex > lastWithdrawnDeex){
            remainderDeex = lastBalanceDeex.sub(lastWithdrawnDeex);
            tokenReturn = (totalDeexSupplyOfDragons.add(totalDeexSupplyOfHamsters)).mul(20).div(100).add(remainderDeex);
            DEEXContract.transfer(team, tokenReturn);
        }

        lastBalanceDeex = DEEXContract.balanceOf(address(this));

        totalSupplyOfHamsters = 0;
        totalSupplyOfDragons = 0;
        totalDeexSupplyOfHamsters = 0;
        totalDeexSupplyOfDragons = 0;
        remainder = 0;
        remainderDeex = 0;
        jackPot = 0;

        withdrawn = 0;
        winner = 0;
        withdrawnDeex = 0;
        countOfDragons = 0;
        countOfHamsters = 0;
        probabilityOfHamsters = 0;
        probabilityOfDragons = 0;

        _setRoundTime(defaultCurrentDeadlineInHours, defaultLastDeadlineInHours);
        currentRound++;
    }

     
    function () external payable {
        if (msg.value == 0){
            require(depositDragons[currentRound - 1][msg.sender] > 0 || depositHamsters[currentRound - 1][msg.sender] > 0);

            uint payout = 0;
            uint payoutDeex = 0;

            if (lastWinner == 1 && depositDragons[currentRound - 1][msg.sender] > 0) {
                payout = calculateLastETHPrize(msg.sender);
            }
            if (lastWinner == 2 && depositHamsters[currentRound - 1][msg.sender] > 0) {
                payout = calculateLastETHPrize(msg.sender);
            }

            if (payout > 0) {
                depositDragons[currentRound - 1][msg.sender] = 0;
                depositHamsters[currentRound - 1][msg.sender] = 0;
                withdrawn = withdrawn.add(payout);
                msg.sender.transfer(payout);
            }

            if ((lastWinner == 1 && depositDragons[currentRound - 1][msg.sender] == 0) || (lastWinner == 2 && depositHamsters[currentRound - 1][msg.sender] == 0)) {
                payoutDeex = calculateLastDeexPrize(msg.sender);
                withdrawnDeex = withdrawnDeex.add(payoutDeex);
                DEEXContract.transfer(msg.sender, payoutDeex);
            }

            if (msg.sender == lastRoundHero) {
                lastHeroHistory = lastRoundHero;
                lastRoundHero = address(0x0);
                withdrawn = withdrawn.add(lastJackPot);
                msg.sender.transfer(lastJackPot);
            }
        }
    }

     
    function calculateETHPrize(address participant) public view returns(uint) {

        uint payout = 0;
        uint256 totalSupply = (totalSupplyOfDragons.add(totalSupplyOfHamsters));

        if (depositDragons[currentRound][participant] > 0) {
            payout = totalSupply.mul(depositDragons[currentRound][participant]).div(totalSupplyOfDragons);
        }

        if (depositHamsters[currentRound][participant] > 0) {
            payout = totalSupply.mul(depositHamsters[currentRound][participant]).div(totalSupplyOfHamsters);
        }

        return payout;
    }

     
    function calculateDeexPrize(address participant) public view returns(uint) {

        uint payout = 0;
        uint totalSupply = (totalDeexSupplyOfDragons.add(totalDeexSupplyOfHamsters)).mul(80).div(100);

        if (depositDragons[currentRound][participant] > 0) {
            payout = totalSupply.mul(depositDragons[currentRound][participant]).div(totalSupplyOfDragons);
        }

        if (depositHamsters[currentRound][participant] > 0) {
            payout = totalSupply.mul(depositHamsters[currentRound][participant]).div(totalSupplyOfHamsters);
        }

        return payout;
    }

     
    function calculateLastETHPrize(address _lastParticipant) public view returns(uint) {

        uint payout = 0;
        uint256 totalSupply = (lastTotalSupplyOfDragons.add(lastTotalSupplyOfHamsters));

        if (depositDragons[currentRound - 1][_lastParticipant] > 0) {
            payout = totalSupply.mul(depositDragons[currentRound - 1][_lastParticipant]).div(lastTotalSupplyOfDragons);
        }

        if (depositHamsters[currentRound - 1][_lastParticipant] > 0) {
            payout = totalSupply.mul(depositHamsters[currentRound - 1][_lastParticipant]).div(lastTotalSupplyOfHamsters);
        }

        return payout;
    }

     
    function calculateLastDeexPrize(address _lastParticipant) public view returns(uint) {

        uint payout = 0;
        uint totalSupply = (lastTotalDeexSupplyOfDragons.add(lastTotalDeexSupplyOfHamsters)).mul(80).div(100);

        if (depositDragons[currentRound - 1][_lastParticipant] > 0) {
            payout = totalSupply.mul(depositDragons[currentRound - 1][_lastParticipant]).div(lastTotalSupplyOfDragons);
        }

        if (depositHamsters[currentRound - 1][_lastParticipant] > 0) {
            payout = totalSupply.mul(depositHamsters[currentRound - 1][_lastParticipant]).div(lastTotalSupplyOfHamsters);
        }

        return payout;
    }
}

 
contract CryptoTeam {
    using SafeMath for uint256;

    Bank public BankContract;
    DEEX public DEEXContract;
    address payable public team = 0x7De1eFb9E5035784FB931433c8a884588929338E;

     
    function () external payable {
        require(BankContract.getState() && msg.value >= 0.05 ether);

        BankContract.setInfo(msg.sender, msg.value.mul(90).div(100));

        team.transfer(msg.value.mul(10).div(100));

        address(BankContract).transfer(msg.value.mul(90).div(100));
    }
}

 
contract Dragons is CryptoTeam {
    constructor(address payable _bankAddress, address payable _DEEXAddress) public {
        BankContract = Bank(_bankAddress);
        BankContract.setDragonsAddress(address(this));
        DEEXContract = DEEX(_DEEXAddress);
        DEEXContract.approve(_bankAddress, 9999999999999999999000000000000000000);
    }
}

 
contract Hamsters is CryptoTeam {
    constructor(address payable _bankAddress, address payable _DEEXAddress) public {
        BankContract = Bank(_bankAddress);
        BankContract.setHamstersAddress(address(this));
        DEEXContract = DEEX(_DEEXAddress);
        DEEXContract.approve(_bankAddress, 9999999999999999999000000000000000000);
    }
}