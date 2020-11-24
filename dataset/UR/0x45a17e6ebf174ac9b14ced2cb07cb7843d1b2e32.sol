 

pragma solidity ^0.5.0;

contract BadBitSettings {

    uint public constant GWEI_TO_WEI = 1000000000;
    uint public constant ETH_TO_WEI = 1000000000000000000;
    uint public ORACLIZE_GAS_LIMIT = 220000;
    uint public MAX_GAS_PRICE = 30000000000;  
    uint public MIN_GAS_PRICE = 1000000000;  
    uint public BIG_WIN_THRESHOLD = 3 ether;
    uint public MAX_CHANCE_FOR_BONUS_BETTING = 25;
    uint public MAX_DON_IN_ROW = 3;
    uint public HOUSE_EDGE = 2000;
    uint public MAX_WP = 9500;
    uint public MIN_WP = 476;
    uint public REVENUE_TO_INITIAL_DEPOSIT_RATIO = 2;
    bool public BETS_ALLOWED = true;
    bool public USE_BLOCKHASH_RANDOM_SEED = false;

     
    mapping(address => bool) public isGameAddress;
     
    mapping(address => bool) public isOperatorAddress;
     
    address[] public gameContractAddresses;
     
    address[] public operators;
     
    uint[] public tokenWinChanceRewardForLevel;
     
    uint[] public bonusBalanceRewardForLevel;

    event GamePaused(bool indexed yes);
    event MaxGasPriceSet(uint amount);
    event MinGasPriceSet(uint amount);
    event BigWinThresholdSet(uint amount);
    event MaxChanceForBonusBetSet(uint amount);
    event MaxDonInRowSet(uint count);
    event HouseEdgeSet(uint houseEdge);
    event MaxWPSet(uint maxWp);
    event MinWPSet(uint minWp);

    modifier onlyOperators() {
        require (isOperatorAddress[msg.sender]);
        _;
    }

    constructor() public {
        operators.push(msg.sender);
        isOperatorAddress[msg.sender] = true;

        bonusBalanceRewardForLevel = [0, 0, 0.01 ether, 0.02 ether, 0,
            0.03 ether, 0.04 ether, 0.05 ether, 0, 0.06 ether, 0.07 ether,
            0.08 ether, 0, 0.09 ether, 0.10 ether, 0.11 ether, 0, 0.12 ether,
            0.13 ether, 0.14 ether, 0, 0.15 ether, 0.16 ether, 0.17 ether, 0,
            0.18 ether, 0.19 ether, 0.20 ether, 0, 0.21 ether, 0.22 ether,
            0.23 ether, 0, 0.24 ether, 0.25 ether, 0.26 ether, 0, 0.27 ether,
            0.28 ether, 0.29 ether, 0, 0.30 ether, 0.31 ether, 0.32 ether, 0,
            0.33 ether, 0.34 ether, 0.35 ether, 0, 0.36 ether, 0.37 ether,
            0.38 ether, 0, 0.39 ether, 0.40 ether, 0.41 ether, 0, 0.42 ether,
            0.43 ether, 0.44 ether, 0, 0.45 ether, 0.46 ether, 0.47 ether, 0,
            0.48 ether, 0.49 ether, 0.50 ether, 0, 0.51 ether, 0.52 ether,
            0.53 ether, 0, 0.54 ether, 0.55 ether, 0.56 ether, 0, 0.57 ether,
            0.58 ether, 0.59 ether, 0, 0.60 ether, 0.61 ether, 0.62 ether, 0,
            0.63 ether, 0.64 ether, 0.65 ether, 0, 0.66 ether, 0.67 ether,
            0.68 ether, 0, 0.69 ether, 0.70 ether, 0.71 ether, 0, 0.72 ether,
            0.73 ether, 0.74 ether, 0];


        tokenWinChanceRewardForLevel = [0, 0, 0, 0, 40, 40, 40, 40, 80, 80, 80, 80,
            120, 120, 120, 120, 160, 160, 160, 160, 200, 200, 200, 200, 250, 250, 250, 250, 300, 300, 300, 300,
            350, 350, 350, 350, 400, 400, 400, 400, 450, 450, 450, 450, 510, 510, 510, 510, 570, 570, 570, 570,
            630, 630, 630, 630, 690, 690, 690, 690, 750, 750, 750, 750, 820, 820, 820, 820, 890, 890, 890, 890,
            960, 960, 960, 960, 1030, 1030, 1030, 1030, 1100, 1100, 1100, 1100, 1180, 1180, 1180, 1180, 1260, 1260, 1260, 1260,
            1340, 1340, 1340, 1340, 1420, 1420, 1420, 1420, 1500];
    }

     
    function addGame(address _address) public onlyOperators {
        require(!isGameAddress[_address]);

        gameContractAddresses.push(_address);
        isGameAddress[_address] = true;
    }

     
    function removeGame(address _address) public onlyOperators {
        require(isGameAddress[_address]);

        uint len = gameContractAddresses.length;

        for (uint i=0; i<len; i++) {
            if (gameContractAddresses[i] == _address) {
                 
                gameContractAddresses[i] = gameContractAddresses[len-1];
                 
                delete gameContractAddresses[len-1];
                 
                gameContractAddresses.length--;
                 
                isGameAddress[_address] = false;
                break;
            }
        }

    }

     
    function addOperator(address _address) public onlyOperators {
        require(!isOperatorAddress[_address]);

        operators.push(_address);
        isOperatorAddress[_address] = true;
    }

     
    function removeOperator(address _address) public onlyOperators {
        require(isOperatorAddress[_address]);

        uint len = operators.length;

        for (uint i=0; i<len; i++) {
            if (operators[i] == _address) {
                 
                operators[i] = operators[len-1];
                 
                delete operators[len-1];
                 
                operators.length--;
                 
                isOperatorAddress[_address] = false;
                break;
            }
        }

    }

    function setMaxGasPriceInGwei(uint _maxGasPrice) public onlyOperators {
        MAX_GAS_PRICE = _maxGasPrice * GWEI_TO_WEI;

        emit MaxGasPriceSet(MAX_GAS_PRICE);
    }

    function setMinGasPriceInGwei(uint _minGasPrice) public onlyOperators {
        MIN_GAS_PRICE = _minGasPrice * GWEI_TO_WEI;

        emit MinGasPriceSet(MIN_GAS_PRICE);
    }

    function setBetsAllowed(bool _betsAllowed) public onlyOperators {
        BETS_ALLOWED = _betsAllowed;

        emit GamePaused(!_betsAllowed);
    }

    function setBigWin(uint _bigWin) public onlyOperators {
        BIG_WIN_THRESHOLD = _bigWin;

        emit BigWinThresholdSet(BIG_WIN_THRESHOLD);
    }

    function setMaxChanceForBonus(uint _chance) public onlyOperators {
        MAX_CHANCE_FOR_BONUS_BETTING = _chance;

        emit MaxChanceForBonusBetSet(MAX_CHANCE_FOR_BONUS_BETTING);
    }

    function setMaxDonInRow(uint _count) public onlyOperators {
        MAX_DON_IN_ROW = _count;

        emit MaxDonInRowSet(MAX_DON_IN_ROW);
    }

    function setHouseEdge(uint _edge) public onlyOperators {
         
        require(_edge < 100000);

        HOUSE_EDGE = _edge;

        emit HouseEdgeSet(HOUSE_EDGE);
    }

    function setOraclizeGasLimit(uint _gas) public onlyOperators {
        ORACLIZE_GAS_LIMIT = _gas;
    }

    function setMaxWp(uint _wp) public onlyOperators {
        MAX_WP = _wp;

        emit MaxWPSet(_wp);
    }

    function setMinWp(uint _wp) public onlyOperators {
        MIN_WP = _wp;

        emit MinWPSet(_wp);
    }

    function setUseBlockhashRandomSeed(bool _use) public onlyOperators {
        USE_BLOCKHASH_RANDOM_SEED = _use;
    }

    function setRevenueToInitialDepositRatio(uint _ratio) public onlyOperators {
        require(_ratio >= 2);

        REVENUE_TO_INITIAL_DEPOSIT_RATIO = _ratio;
    }

    function getOperators() public view returns(address[] memory) {
        return operators;
    }

    function getGames() public view returns(address[] memory) {
        return gameContractAddresses;
    }

    function getNumberOfGames() public view returns(uint) {
        return gameContractAddresses.length;
    }
}