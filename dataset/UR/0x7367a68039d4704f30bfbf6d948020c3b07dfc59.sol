 

pragma solidity ^0.4.19;


 
contract InternalBeercoin {
     
    uint256 internal constant INITIAL_SUPPLY = 15496000000 * 10**18;
    uint256 internal constant DIAMOND_VALUE = 10000 * 10**18;
    uint256 internal constant GOLD_VALUE = 100 * 10**18;
    uint256 internal constant SILVER_VALUE = 10 * 10**18;
    uint256 internal constant BRONZE_VALUE = 1 * 10**18;

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    uint64 internal producibleCaps = 20800000000;

     
     
     
     
     
     
     
     
     
     
     
     
     
    uint256 internal packedProducedCaps = 0;
    uint256 internal packedScannedCaps = 0;

     
    uint256 internal burntValue = 0;
}


 
contract ExplorableBeercoin is InternalBeercoin {
     
    function unproducedCaps() public view returns (uint64) {
        return producibleCaps;
    }

     
    function unscannedCaps() public view returns (uint64) {
        uint256 caps = packedProducedCaps - packedScannedCaps;
        uint64 amount = uint64(caps >> 192);
        amount += uint64(caps >> 128);
        amount += uint64(caps >> 64);
        amount += uint64(caps);
        return amount;
    }

     
    function producedCaps() public view returns (uint64) {
        uint256 caps = packedProducedCaps;
        uint64 amount = uint64(caps >> 192);
        amount += uint64(caps >> 128);
        amount += uint64(caps >> 64);
        amount += uint64(caps);
        return amount;
    }

     
    function scannedCaps() public view returns (uint64) {
        uint256 caps = packedScannedCaps;
        uint64 amount = uint64(caps >> 192);
        amount += uint64(caps >> 128);
        amount += uint64(caps >> 64);
        amount += uint64(caps);
        return amount;
    }

     
    function producedDiamondCaps() public view returns (uint64) {
        return uint64(packedProducedCaps >> 192);
    }

     
    function scannedDiamondCaps() public view returns (uint64) {
        return uint64(packedScannedCaps >> 192);
    }

     
    function producedGoldCaps() public view returns (uint64) {
        return uint64(packedProducedCaps >> 128);
    }

     
    function scannedGoldCaps() public view returns (uint64) {
        return uint64(packedScannedCaps >> 128);
    }

     
    function producedSilverCaps() public view returns (uint64) {
        return uint64(packedProducedCaps >> 64);
    }

     
    function scannedSilverCaps() public view returns (uint64) {
        return uint64(packedScannedCaps >> 64);
    }

     
    function producedBronzeCaps() public view returns (uint64) {
        return uint64(packedProducedCaps);
    }

     
    function scannedBronzeCaps() public view returns (uint64) {
        return uint64(packedScannedCaps);
    }
}


 
contract ERC20Beercoin is ExplorableBeercoin {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowances;

     
    function name() public pure returns (string) {
        return "Beercoin";
    }

     
    function symbol() public pure returns (string) {
        return "🍺";
    }

     
    function decimals() public pure returns (uint8) {
        return 18;
    }

     
    function totalSupply() public view returns (uint256) {
        uint256 caps = packedScannedCaps;
        uint256 supply = INITIAL_SUPPLY;
        supply += (caps >> 192) * DIAMOND_VALUE;
        supply += ((caps >> 128) & 0xFFFFFFFFFFFFFFFF) * GOLD_VALUE;
        supply += ((caps >> 64) & 0xFFFFFFFFFFFFFFFF) * SILVER_VALUE;
        supply += (caps & 0xFFFFFFFFFFFFFFFF) * BRONZE_VALUE;
        return supply - burntValue;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != 0x0);

        uint256 balanceFrom = balances[msg.sender];

        require(_value <= balanceFrom);

        uint256 oldBalanceTo = balances[_to];
        uint256 newBalanceTo = oldBalanceTo + _value;

        require(oldBalanceTo <= newBalanceTo);

        balances[msg.sender] = balanceFrom - _value;
        balances[_to] = newBalanceTo;

        Transfer(msg.sender, _to, _value);

        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != 0x0);

        uint256 balanceFrom = balances[_from];
        uint256 allowanceFrom = allowances[_from][msg.sender];

        require(_value <= balanceFrom);
        require(_value <= allowanceFrom);

        uint256 oldBalanceTo = balances[_to];
        uint256 newBalanceTo = oldBalanceTo + _value;

        require(oldBalanceTo <= newBalanceTo);

        balances[_from] = balanceFrom - _value;
        balances[_to] = newBalanceTo;
        allowances[_from][msg.sender] = allowanceFrom - _value;

        Transfer(_from, _to, _value);

        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }
}


 
contract MasteredBeercoin is ERC20Beercoin {
    address internal beercoinMaster;
    mapping (address => bool) internal directDebitAllowances;

     
    function MasteredBeercoin() public {
        beercoinMaster = msg.sender;
    }

     
    modifier onlyMaster {
        require(msg.sender == beercoinMaster);
        _;
    }

     
    function master() public view returns (address) {
        return beercoinMaster;
    }

     
    function declareNewMaster(address newMaster) public onlyMaster {
        beercoinMaster = newMaster;
    }

     
    function allowDirectDebit() public {
        directDebitAllowances[msg.sender] = true;
    }

     
    function forbidDirectDebit() public {
        directDebitAllowances[msg.sender] = false;
    }

     
    function directDebitAllowance(address user) public view returns (bool) {
        return directDebitAllowances[user];
    }

     
    function debit(address[] users, uint256[] values) public onlyMaster returns (bool) {
        require(users.length == values.length);

        uint256 oldBalance = balances[msg.sender];
        uint256 newBalance = oldBalance;

        address currentUser;
        uint256 currentValue;
        uint256 currentBalance;
        for (uint256 i = 0; i < users.length; ++i) {
            currentUser = users[i];
            currentValue = values[i];
            currentBalance = balances[currentUser];

            require(directDebitAllowances[currentUser]);
            require(currentValue <= currentBalance);
            balances[currentUser] = currentBalance - currentValue;
            
            newBalance += currentValue;

            Transfer(currentUser, msg.sender, currentValue);
        }

        require(oldBalance <= newBalance);
        balances[msg.sender] = newBalance;

        return true;
    }

     
    function debitEqually(address[] users, uint256 value) public onlyMaster returns (bool) {
        uint256 oldBalance = balances[msg.sender];
        uint256 newBalance = oldBalance + (users.length * value);

        require(oldBalance <= newBalance);
        balances[msg.sender] = newBalance;

        address currentUser;
        uint256 currentBalance;
        for (uint256 i = 0; i < users.length; ++i) {
            currentUser = users[i];
            currentBalance = balances[currentUser];

            require(directDebitAllowances[currentUser]);
            require(value <= currentBalance);
            balances[currentUser] = currentBalance - value;

            Transfer(currentUser, msg.sender, value);
        }

        return true;
    }

     
    function credit(address[] users, uint256[] values) public onlyMaster returns (bool) {
        require(users.length == values.length);

        uint256 balance = balances[msg.sender];
        uint256 totalValue = 0;

        address currentUser;
        uint256 currentValue;
        uint256 currentOldBalance;
        uint256 currentNewBalance;
        for (uint256 i = 0; i < users.length; ++i) {
            currentUser = users[i];
            currentValue = values[i];
            currentOldBalance = balances[currentUser];
            currentNewBalance = currentOldBalance + currentValue;

            require(currentOldBalance <= currentNewBalance);
            balances[currentUser] = currentNewBalance;

            totalValue += currentValue;

            Transfer(msg.sender, currentUser, currentValue);
        }

        require(totalValue <= balance);
        balances[msg.sender] = balance - totalValue;

        return true;
    }

     
    function creditEqually(address[] users, uint256 value) public onlyMaster returns (bool) {
        uint256 balance = balances[msg.sender];
        uint256 totalValue = users.length * value;

        require(totalValue <= balance);
        balances[msg.sender] = balance - totalValue;

        address currentUser;
        uint256 currentOldBalance;
        uint256 currentNewBalance;
        for (uint256 i = 0; i < users.length; ++i) {
            currentUser = users[i];
            currentOldBalance = balances[currentUser];
            currentNewBalance = currentOldBalance + value;

            require(currentOldBalance <= currentNewBalance);
            balances[currentUser] = currentNewBalance;

            Transfer(msg.sender, currentUser, value);
        }

        return true;
    }
}


 
contract Beercoin is MasteredBeercoin {
    event Produce(uint256 newCaps);
    event Scan(address[] users, uint256[] caps);
    event Burn(uint256 value);

     
    function Beercoin() public {
        balances[msg.sender] = INITIAL_SUPPLY;
    }

     
    function produce(uint64 numberOfCaps) public onlyMaster returns (bool) {
        require(numberOfCaps <= producibleCaps);

        uint256 producedCaps = packedProducedCaps;

        uint64 targetTotalCaps = numberOfCaps;
        targetTotalCaps += uint64(producedCaps >> 192);
        targetTotalCaps += uint64(producedCaps >> 128);
        targetTotalCaps += uint64(producedCaps >> 64);
        targetTotalCaps += uint64(producedCaps);

        uint64 targetDiamondCaps = (targetTotalCaps - (targetTotalCaps % 10000)) / 10000;
        uint64 targetGoldCaps = ((targetTotalCaps - (targetTotalCaps % 1000)) / 1000) - targetDiamondCaps;
        uint64 targetSilverCaps = ((targetTotalCaps - (targetTotalCaps % 10)) / 10) - targetDiamondCaps - targetGoldCaps;
        uint64 targetBronzeCaps = targetTotalCaps - targetDiamondCaps - targetGoldCaps - targetSilverCaps;

        uint256 targetProducedCaps = 0;
        targetProducedCaps |= uint256(targetDiamondCaps) << 192;
        targetProducedCaps |= uint256(targetGoldCaps) << 128;
        targetProducedCaps |= uint256(targetSilverCaps) << 64;
        targetProducedCaps |= uint256(targetBronzeCaps);

        producibleCaps -= numberOfCaps;
        packedProducedCaps = targetProducedCaps;

        Produce(targetProducedCaps - producedCaps);

        return true;
    }

     
    function scan(address[] users, uint256[] caps) public onlyMaster returns (bool) {
        require(users.length == caps.length);

        uint256 scannedCaps = packedScannedCaps;

        uint256 currentCaps;
        uint256 capsValue;
        for (uint256 i = 0; i < users.length; ++i) {
            currentCaps = caps[i];

            capsValue = DIAMOND_VALUE * (currentCaps >> 192);
            capsValue += GOLD_VALUE * ((currentCaps >> 128) & 0xFFFFFFFFFFFFFFFF);
            capsValue += SILVER_VALUE * ((currentCaps >> 64) & 0xFFFFFFFFFFFFFFFF);
            capsValue += BRONZE_VALUE * (currentCaps & 0xFFFFFFFFFFFFFFFF);

            balances[users[i]] += capsValue;
            scannedCaps += currentCaps;
        }

        require(scannedCaps <= packedProducedCaps);
        packedScannedCaps = scannedCaps;

        Scan(users, caps);

        return true;
    }

     
    function burn(uint256 value) public onlyMaster returns (bool) {
        uint256 balance = balances[msg.sender];
        require(value <= balance);

        balances[msg.sender] = balance - value;
        burntValue += value;

        Burn(value);

        return true;
    }
}