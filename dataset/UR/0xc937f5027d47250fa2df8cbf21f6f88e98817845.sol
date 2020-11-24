 
     
    string  public name = "GoldReserve";
    string  public symbol = "XGR";
    uint8   public decimals = 8;
    uint256 public transactionFeeRate   = 20;  
    uint256 public transactionFeeRateM  = 1e3;  
    uint256 public transactionFeeMin    =   2000000;  
    uint256 public transactionFeeMax    = 200000000;  
    address public databaseAddress;
    address public depositsAddress;
    address public forkAddress;
    address public libAddress;
     
    function Token(address newDatabaseAddress, address newDepositAddress, address newFrokAddress, address newLibAddress) public {
        databaseAddress = newDatabaseAddress;
        depositsAddress = newDepositAddress;
        forkAddress = newFrokAddress;
        libAddress = newLibAddress;
    }
     
    function () {
        revert();
    }
     
    function changeDataBaseAddress(address newDatabaseAddress) external onlyForOwner {
        databaseAddress = newDatabaseAddress;
    }
    function changeDepositsAddress(address newDepositsAddress) external onlyForOwner {
        depositsAddress = newDepositsAddress;
    }
    function changeForkAddress(address newForkAddress) external onlyForOwner {
        forkAddress = newForkAddress;
    }
    function changeLibAddress(address newLibAddress) external onlyForOwner {
        libAddress = newLibAddress;
    }
    function changeFees(uint256 rate, uint256 rateMultiplier, uint256 min, uint256 max) external onlyForOwner {
        transactionFeeRate = rate;
        transactionFeeRateM = rateMultiplier;
        transactionFeeMin = min;
        transactionFeeMax = max;
    }
     
    function approve(address spender, uint256 amount) external returns (bool _success) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
     
    function transfer(address to, uint256 amount) external returns (bool success) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
     
    function transferFrom(address from, address to, uint256 amount) external returns (bool success) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
     
    function transfer(address to, uint256 amount, bytes extraData) external returns (bool success) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
    function mint(address owner, uint256 value) external returns (bool success) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
     
     
    function allowance(address owner, address spender) public constant returns (uint256 remaining, uint256 nonce) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x40)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x40)
            }
        }
    }
    function getTransactionFee(uint256 value) public constant returns (bool success, uint256 fee) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x40)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x40)
            }
        }
    }
    function balanceOf(address owner) public constant returns (uint256 value) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
    function balancesOf(address owner) public constant returns (uint256 balance, uint256 lockedAmount) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x40)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x40)
            }
        }
    }
    function totalSupply() public constant returns (uint256 value) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
     
    event AllowanceUsed(address indexed spender, address indexed owner, uint256 indexed value);
    event Mint(address indexed addr, uint256 indexed value);
    event Burn(address indexed addr, uint256 indexed value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Transfer2(address indexed from, address indexed to, uint256 indexed value, bytes data);
}
