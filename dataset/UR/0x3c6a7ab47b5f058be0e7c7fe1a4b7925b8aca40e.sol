 

pragma solidity 0.4.15;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Ownable {
     
    address public owner;

    address public newOwner;

     
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;

    }

    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract ERC20 is Ownable {
    using SafeMath for uint256;

     
    string public standard;

    string public name;

    string public symbol;

    uint8 public decimals;

    uint256 public totalSupply;

    bool public locked;

    uint256 public creationBlock;

    mapping (address => uint256) public balanceOf;

    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

     
    function ERC20(
        uint256 _totalSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        bool transferAllSupplyToOwner,
        bool _locked
    ) public {
        standard = "ERC20 0.1";

        totalSupply = _totalSupply;

        if (transferAllSupplyToOwner) {
            setBalance(msg.sender, totalSupply);

            Transfer(0, msg.sender, totalSupply);
        } else {
            setBalance(this, totalSupply);

            Transfer(0, this, totalSupply);
        }

        name = tokenName;
         
        symbol = tokenSymbol;
         
        decimals = decimalUnits;
         
        locked = _locked;
        creationBlock = block.number;
    }

    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) {
        require(locked == false);

        bool status = transferInternal(msg.sender, _to, _value);

        require(status == true);
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (locked) {
            return false;
        }

        allowance[msg.sender][_spender] = _value;

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (locked) {
            return false;
        }

        if (allowance[_from][msg.sender] < _value) {
            return false;
        }

        bool _success = transferInternal(_from, _to, _value);

        if (_success) {
            allowance[_from][msg.sender] -= _value;
        }

        return _success;
    }
     

    function setBalance(address holder, uint256 amount) internal {
        balanceOf[holder] = amount;
    }

    function transferInternal(address _from, address _to, uint256 value) internal returns (bool success) {
        if (value == 0) {
            return false;
        }

        if (balanceOf[_from] < value) {
            return false;
        }

        setBalance(_from, balanceOf[_from].sub(value));
        setBalance(_to, balanceOf[_to].add(value));

        Transfer(_from, _to, value);

        return true;
    }
}

contract LoggedERC20 is ERC20 {
     
    struct LogValueBlock {
        uint256 value;
        uint256 block;
    }

    LogValueBlock[] public loggedTotalSupply;

     
    mapping (address => LogValueBlock[]) public loggedBalances;

     
    function LoggedERC20(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        bool transferAllSupplyToOwner,
        bool _locked
    )	public
        ERC20(initialSupply, tokenName, decimalUnits, tokenSymbol, transferAllSupplyToOwner, _locked)
    {
        standard = "LogValueBlockToken 0.1";
    }

    function valueAt(LogValueBlock[] storage valueBlocks, uint256 _block) internal returns (uint256) {
        if (valueBlocks.length == 0) {
            return 0;
        }

        if (valueBlocks[0].block > _block) {
            return 0;
        }

        if (valueBlocks[valueBlocks.length.sub(1)].block <= _block) {
            return valueBlocks[valueBlocks.length.sub(1)].value;
        }

        uint256 first = 0;
        uint256 last = valueBlocks.length.sub(1);

        uint256 middle = (first.add(last).add(1)).div(2);

        while (last > first) {
            if (valueBlocks[middle].block <= _block) {
                first = middle;
            } else {
                last = middle.sub(1);
            }

            middle = (first.add(last).add(1)).div(2);
        }

        return valueBlocks[first].value;
    }

    function setBalance(address _address, uint256 value) internal {
        loggedBalances[_address].push(LogValueBlock(value, block.number));

        balanceOf[_address] = value;
    }
}

contract LoggedDividend is Ownable, LoggedERC20 {
     
    struct Dividend {
        uint256 id;

        uint256 block;
        uint256 time;
        uint256 amount;

        uint256 claimedAmount;
        uint256 transferedBack;

        uint256 totalSupply;
        uint256 recycleTime;

        bool recycled;

        mapping (address => bool) claimed;
    }

     
    Dividend[] public dividends;

    mapping (address => uint256) dividendsClaimed;

     
    event DividendTransfered(
        uint256 id,
        address indexed _address,
        uint256 _block,
        uint256 _amount,
        uint256 _totalSupply
    );

    event DividendClaimed(uint256 id, address indexed _address, uint256 _claim);

    event UnclaimedDividendTransfer(uint256 id, uint256 _value);

    event DividendRecycled(
        uint256 id,
        address indexed _recycler,
        uint256 _blockNumber,
        uint256 _amount,
        uint256 _totalSupply
    );
    
    function LoggedDividend(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        bool transferAllSupplyToOwner,
        bool _locked
    ) 
		public
		LoggedERC20(initialSupply, tokenName, decimalUnits, tokenSymbol, transferAllSupplyToOwner, _locked) {
        
    }

    function addDividend(uint256 recycleTime) public payable onlyOwner {
        require(msg.value > 0);

        uint256 id = dividends.length;
        uint256 _totalSupply = totalSupply;

        dividends.push(
            Dividend(
                id,
                block.number,
                now,
                msg.value,
                0,
                0,
                _totalSupply,
                recycleTime,
                false
            )
        );

        DividendTransfered(id, msg.sender, block.number, msg.value, _totalSupply);
    }

    function claimDividend(uint256 dividendId) public returns (bool) {
        if ((dividends.length).sub(1) < dividendId) {
            return false;
        }

        Dividend storage dividend = dividends[dividendId];

        if (dividend.claimed[msg.sender] == true) {
            return false;
        }

        if (dividend.recycled == true) {
            return false;
        }

        if (now >= dividend.time.add(dividend.recycleTime)) {
            return false;
        }

        uint256 balance = valueAt(loggedBalances[msg.sender], dividend.block);

        if (balance == 0) {
            return false;
        }

        uint256 claim = balance.mul(dividend.amount).div(dividend.totalSupply);

        dividend.claimed[msg.sender] = true;

        dividend.claimedAmount = dividend.claimedAmount.add(claim);

        if (claim > 0) {
            msg.sender.transfer(claim);
            DividendClaimed(dividendId, msg.sender, claim);

            return true;
        }

        return false;
    }

    function claimDividends() public {
        require(dividendsClaimed[msg.sender] < dividends.length);
        for (uint i = dividendsClaimed[msg.sender]; i < dividends.length; i++) {
            if ((dividends[i].claimed[msg.sender] == false) && (dividends[i].recycled == false)) {
                dividendsClaimed[msg.sender] = i.add(1);
                claimDividend(i);
            }
        }
    }

    function recycleDividend(uint256 dividendId) public onlyOwner returns (bool success) {
        if (dividends.length.sub(1) < dividendId) {
            return false;
        }

        Dividend storage dividend = dividends[dividendId];

        if (dividend.recycled) {
            return false;
        }

        dividend.recycled = true;

        return true;
    }

    function refundUnclaimedEthers(uint256 dividendId) public onlyOwner returns (bool success) {
        if ((dividends.length).sub(1) < dividendId) {
            return false;
        }

        Dividend storage dividend = dividends[dividendId];

        if (dividend.recycled == false) {
            if (now < (dividend.time).add(dividend.recycleTime)) {
                return false;
            }
        }

        uint256 claimedBackAmount = (dividend.amount).sub(dividend.claimedAmount);

        dividend.transferedBack = claimedBackAmount;

        if (claimedBackAmount > 0) {
            owner.transfer(claimedBackAmount);

            UnclaimedDividendTransfer(dividendId, claimedBackAmount);

            return true;
        }

        return false;
    }
}

contract PhaseICO is LoggedDividend {
    uint256 public icoSince;
    uint256 public icoTill;

    uint256 public collectedEthers;

    Phase[] public phases;

    struct Phase {
        uint256 price;
        uint256 maxAmount;
    }
    
    function PhaseICO(
        uint256 _icoSince,
        uint256 _icoTill,
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint8 precision,
        bool transferAllSupplyToOwner,
        bool _locked
    ) 
		public
		LoggedDividend(initialSupply, tokenName, precision, tokenSymbol, transferAllSupplyToOwner, _locked) {
        standard = "PhaseICO 0.1";

        icoSince = _icoSince;
        icoTill = _icoTill;
    }

    function() public payable {
        bool status = buy(msg.sender, now, msg.value);

        require(status == true);
    }

    function getIcoTokensAmount(uint256 _collectedEthers, uint256 value) public  constant returns (uint256) {
        uint256 amount;

        uint256 newCollectedEthers = _collectedEthers;
        uint256 remainingValue = value;
        
        for (uint i = 0; i < phases.length; i++) {
            Phase storage phase = phases[i];

            if (phase.maxAmount > newCollectedEthers) {
                if (newCollectedEthers.add(remainingValue) > phase.maxAmount) {
                    uint256 diff = phase.maxAmount.sub(newCollectedEthers);

                    amount = amount.add(diff.mul(1 ether).div(phase.price));

                    remainingValue = remainingValue.sub(diff);
                    newCollectedEthers = newCollectedEthers.add(diff);
                } else {
                    amount += remainingValue * 1 ether / phase.price;

                    newCollectedEthers += remainingValue;

                    remainingValue = 0;
                }
            }

            if (remainingValue == 0) {
                break;
            }
        }
        
        if (remainingValue > 0) {
            return 0;
        }

        return amount;
    }

    function buy(address _address, uint256 time, uint256 value) internal returns (bool) {
        if (locked == true) {
            return false;
        }

        if (time < icoSince || time > icoTill) {
            return false;
        }

        if (value == 0) {
            return false;
        }

        uint256 amount = getIcoTokensAmount(collectedEthers, value);

        if (amount == 0) {
            return false;
        }

        uint256 selfBalance = valueAt(loggedBalances[this], block.number);
        uint256 holderBalance = valueAt(loggedBalances[_address], block.number);

        if (selfBalance < amount) {
            return false;
        }

        setBalance(_address, holderBalance.add(amount));
        setBalance(this, selfBalance.sub(amount));

        collectedEthers = collectedEthers.add(value);

        Transfer(this, _address, amount);

        return true;
    }
}

contract Cajutel is PhaseICO {

    address public migrateAddress;

    modifier onlyMigrate() {
        require(migrateAddress == msg.sender);
        _;
    }

    function Cajutel(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint256 icoSince,
        uint256 icoTill
    ) PhaseICO(icoSince, icoTill, initialSupply, tokenName, tokenSymbol, 18, false, false) {
        standard = "Cajutel 0.1";

        phases.push(Phase(0.05 ether, 500 ether));
        phases.push(Phase(0.075 ether, 750 ether + 500 ether));
        phases.push(Phase(0.1 ether, 10000 ether + 750 ether + 500 ether));
        phases.push(Phase(0.15 ether, 30000 ether + 10000 ether + 750 ether + 500 ether));
        phases.push(Phase(0.2 ether, 80000 ether + 30000 ether + 10000 ether + 750 ether + 500 ether));
    
    }

     
    function setMigrateAddress(address _address) public onlyOwner {
        migrateAddress = _address;
    }

    function transferEthers() public onlyOwner {
        owner.transfer(this.balance);
    }

    function setLocked(bool _locked) public onlyOwner {
        locked = _locked;
    }

    function setIcoDates(uint256 _icoSince, uint256 _icoTill) public onlyOwner {
        icoSince = _icoSince;
        icoTill = _icoTill;
    }

    function setMigratedBalance(address _holderAddress, uint256 _value) public onlyMigrate {
        require(balanceOf[this].sub(_value) >= 0);
        setBalance(_holderAddress, _value);
        setBalance(this, balanceOf[this].sub(_value));
        Transfer(this, _holderAddress, _value);
    }
}

contract MigrateBalances is Ownable {

    Balance[] public balances;

    bool public balancesSet;

    struct Balance {
        address holderAddress;
        uint256 amount;
        bool migrated;
    }

    Cajutel public newCajutel;

    function MigrateBalances(address _newCajutel) public {
        require(_newCajutel != address(0));
        newCajutel = Cajutel(_newCajutel);


    }
     
     
    function setBalances() public onlyOwner {
        require(false == balancesSet);
        balancesSet = true;
        balances.push(Balance(0x15d9250358489Ceb509121963Ff80e747c7F981f, 900246000000000000000000, false));
        balances.push(Balance(0x21C5DfD6FccA838634D0039c9B15B7bA57Bd6298, 100000000000000000000000, false));
        balances.push(Balance(0x716134814fD704C3b7C2d829068d70962D942FdA, 49888300000000000000000, false));
        balances.push(Balance(0xb719f3A03293A71fB840b1e32C79EE6885A9C771, 8290600000000000000000, false));
        balances.push(Balance(0x9e1F7671149a6888DCf3882c6Ab1408aBdE6E102, 3000000000000000000000, false));
        balances.push(Balance(0xAF691ED473eBE4fbF90A7Ceaf0E29b2D82c293fC, 2000000000000000000000, false));
        balances.push(Balance(0x255e1dAB5bA7c575951E12286f7c3B6714CFeE92, 1000000000000000000000, false));
        balances.push(Balance(0x8d12A197cB00D4747a1fe03395095ce2A5CC6819, 1000000000000000000000, false));
        balances.push(Balance(0xBcEa2d09C05691B0797DeD95D07836aD5551Cb78, 500000000000000000000, false));
        balances.push(Balance(0x6270e2C43d89AcED92955b6D47b455627Ba75B57, 380000000000000000000, false));
        balances.push(Balance(0x2321A30FF9dFD1edE3718b11a2C74118Eb673f75, 200000000000000000000, false));
        balances.push(Balance(0x9BE1c7a1F118F61740f01e96d292c0bae90360aB, 171000000000000000000, false));
        balances.push(Balance(0x390bef0e73e51C4daaF70fDA390fa8da6EA07D88, 145000000000000000000, false));
        balances.push(Balance(0xA79dfeaE0D50d723fc333995C664Fcf3Ca8d7455, 113000000000000000000, false));
        balances.push(Balance(0x4aB7dA32F383e618522eD9724b1c19C63d409FbE, 111625924457445000000, false));
        balances.push(Balance(0xb00D6EDDF69dCcE079bd615196967CE596661951, 108000000000000000000, false));
        balances.push(Balance(0x9c60b97Cb5A10182fd69B5D022A75F1A74e598cF, 102359033442992000000, false));
        balances.push(Balance(0xbCf6e1fa53243f319788E63E91F89e9A43F5D8B4, 100000000000000000000, false));
        balances.push(Balance(0x5870d3b1e32721cAB6804e6497092f0f38804f14, 100000000000000000000, false));
        balances.push(Balance(0x00BC7d1910Bc4424AEd7EDDF5E5a008931625C28, 100000000000000000000, false));
        balances.push(Balance(0xcbFb05E6Ff8054663959dFD842f80BDAC06B40D7, 99000000000000000000, false));
        balances.push(Balance(0xFdF758e6c2dE14a056d96B06f2c55333FBB089c8, 80000000000000000000, false));
        balances.push(Balance(0xcE735a5c6FEB88DD7D13b5Faa7c27894eb4E5AE0, 80000000000000000000, false));
        balances.push(Balance(0x3B1D9FD8862AED71BC56fffE45a74F110ee4bB30, 76324349107581500000, false));
        balances.push(Balance(0xD649F8260C194bBC02302c6360398678482B484A, 76000000000000000000, false));
        balances.push(Balance(0xc3e53F02FEcdB6D1EfeDAA4e5bb504b74EDbDc2B, 64000000000000000000, false));
        balances.push(Balance(0x74a6Fd23EFEABd5C1ec6DB56A012124Bb8096326, 60000000000000000000, false));
        balances.push(Balance(0x15AD355116A4Ce684B26f67A9458924976a3A895, 60000000000000000000, false));
        balances.push(Balance(0x7B120968eEdd48865CA44b913A2437B876f5e295, 60000000000000000000, false));
        balances.push(Balance(0x4ECABB300a16Ec35AF215BDA39637F9993A3c7Ac, 58666666666666700000, false));
        balances.push(Balance(0x807D077060A71b9d84A6a53a67369177BdFc61DD, 52292213506666700000, false));
        balances.push(Balance(0x6D8864eEB5e292e49F9E65276296691f935d93F8, 51986666666666600000, false));
        balances.push(Balance(0x404C0d6424EF6A07843dF75fdeE528918387ca05, 50000000000000000000, false));
        balances.push(Balance(0x7D8679e2681B69F73D87DB4CD72477738D9CDB28, 50000000000000000000, false));
        balances.push(Balance(0x57B734d29122882570Ee2FcBD75F6c438CBD1c5F, 49078842800000000000, false));
        balances.push(Balance(0xf818d8a6588fdc5eF13c62D63Adb477f242F2225, 48000000000000000000, false));
        balances.push(Balance(0x3AA5F7CfeAc40495C8e89551B716DEa4a61BB6C1, 45200000000000000000, false));
        balances.push(Balance(0x70057E29C1c1166EB4f5625DDCf2AAC3AffAC682, 41666666666666700000, false));
        balances.push(Balance(0x623B56D702468AA253cF81383765A510998b3A3F, 41400000000000000000, false));
        balances.push(Balance(0xc2Fe74A950b7b657ddB8D23B143e02CB2806EC8D, 41000000000000000000, false));
        balances.push(Balance(0x433D67a103661159d6867e96867c18D2292B093B, 40060026820483100000, false));
        balances.push(Balance(0xeE526282ad8Ab39a43F3202DBBA380762A92667E, 40000000000000000000, false));
        balances.push(Balance(0xdbf9d1127AD20B14Df8f5b19719831bF0496d443, 40000000000000000000, false));
        balances.push(Balance(0xDBADecbb2e5d5e70a488830296a8918920a4D41F, 40000000000000000000, false));
        balances.push(Balance(0x82d2Edb5024A255bFdbCE618E7f341D1DEe14a4B, 40000000000000000000, false));
        balances.push(Balance(0x8cF84382DB1Ccf1ed1b32c0187db644b35cbc299, 40000000000000000000, false));
        balances.push(Balance(0x68C9D9912cd56E415Bfd3A31651f98006F89b410, 38666666666666700000, false));
        balances.push(Balance(0x0e9691088A658DDF416DB57d02ad7DeF173ef74C, 38000000000000000000, false));
        balances.push(Balance(0x078cfD085962f8dB8B3eaD10Ce9009f366CF51d8, 37000000000000000000, false));
        balances.push(Balance(0xe553D979278bDBc0927c1667C2314A5446315be8, 35000000000000000000, false));
        balances.push(Balance(0xa1D6A35d3B13Cca6d56cB7D07Da9a89F4c3C0C4a, 35000000000000000000, false));
        balances.push(Balance(0x5BE78822bb773112969Aac90BBfc837fAE8D2ac7, 32600000000000000000, false));
        balances.push(Balance(0x3e9719f94F7BFBcDD2F1D66a18236D942fF4a087, 30082572981493200000, false));
        balances.push(Balance(0xea9C95FB771De9e1E19aA25cA2E190aE96466CDD, 30000000000000000000, false));
        balances.push(Balance(0xfFFd54E22263F13447032E3941729884e03F4d58, 29280000000000000000, false));
        balances.push(Balance(0xC5E522c2aAbAcf8182EA97277f60Ef9E6787f03d, 29000000000000000000, false));
        balances.push(Balance(0x5105BA072ADCe7D7F993Eec00a1deEA82015422f, 27000000000000000000, false));
        balances.push(Balance(0xb7A4E02F126fbD35e9365a4D51c414697DceF063, 26666666666666700000, false));
        balances.push(Balance(0x909B749D2330c3b374FcDb4B9B599942583F4E1E, 26666666666666600000, false));
        balances.push(Balance(0x8FddF2D321A5F6d3DAc50c3Cfe0b773e78BBe79D, 26400000000000000000, false));
        balances.push(Balance(0xbFA4fA007b5B0C946e740334A4Ff7d977244e705, 26000000000000000000, false));
        balances.push(Balance(0x802e2a1CfdA97311009D9b0CC253CfB7f824c40c, 25333333333333300000, false));
        balances.push(Balance(0x5d8d29BEFe9eB053aF67D776b7E3cECdA07A9E10, 25000000000000000000, false));
        balances.push(Balance(0x51908426DE197677a73963581952dFf87E825480, 24000000000000000000, false));
        balances.push(Balance(0x893b6CF80B613A394220BEBe01Cd4C616470B0C7, 24000000000000000000, false));
        balances.push(Balance(0xC08A6c874E43B4AA42DE6591E8be593f2557fF8C, 23700000000000000000, false));
        balances.push(Balance(0xFD2CF1F76a931D441F67fB73D05E211E89b0d9C7, 22000000000000000000, false));
        balances.push(Balance(0xF828be1B6e274FfB28E1Ea948cBde24efE8948e9, 22000000000000000000, false));
        balances.push(Balance(0x8ecDd5B4bD04d3b33B6591D9083AFAA6EBf9171b, 20800000000000000000, false));
        balances.push(Balance(0x19d51226d74fbe6367601039235598745EC2907c, 20181333333333300000, false));
        balances.push(Balance(0xfC73413D8dCc28D271cdE376835EdF6690Fa91a8, 20000000000000000000, false));
        balances.push(Balance(0xD24D4B5f7Ea0ECF4664FE3E5efF357E4abAe9faA, 20000000000000000000, false));
        balances.push(Balance(0xC9e29bacE9f74baFff77919A803852C553BC89E5, 20000000000000000000, false));
        balances.push(Balance(0xbEADCd526616ffBF31A613Ca95AC0F665986C90A, 20000000000000000000, false));
        balances.push(Balance(0xa88c9a308B920090427B8814ae0E79ce294B2F6F, 20000000000000000000, false));
        balances.push(Balance(0x8630F7577dd24afD574f6ddB4A4c640d2abae482, 20000000000000000000, false));
        balances.push(Balance(0x787e6870754Cc306C1758db62DC6Cd334bA76345, 20000000000000000000, false));
        balances.push(Balance(0x146cA2f2b923517EabE39367B9bAb530ab6114B6, 20000000000000000000, false));
        balances.push(Balance(0x7Ff7c0630227442C1428d55aDca6A722e442c364, 20000000000000000000, false));
        balances.push(Balance(0x00CfbBb1609C6F183a4bc7061fA72c09F62d7691, 20000000000000000000, false));
        balances.push(Balance(0x1ABfAB721Ff6317F8bD3bc3BCDAED8F794B4b03e, 19800000000000000000, false));
        balances.push(Balance(0xC4f4361035d7E646E09F910e94a5D9F200D697d1, 19773874840000000000, false));
        balances.push(Balance(0x4AB9fC8553793cedC64b9562F41701eBF49d7Bb8, 19000000000000000000, false));
    }
     

    function setNewCajutel(address _cajutel) public onlyOwner {
        require(_cajutel != address(0));
        newCajutel = Cajutel(_cajutel);
    }

    function getBalancesLength() public constant onlyOwner returns (uint256) {
        return balances.length;
    }

    function doMigration(uint256 _start, uint256 _finish) public onlyOwner {
        if (_finish == 0) {
            _finish = balances.length;
        }
        require(_finish < balances.length);
        for (uint i = _start; i <= _finish; i++) {
            Balance storage balance = balances[i];
            if (balance.migrated == true) {
                continue;
            }
            if (balance.amount > 0) {
                newCajutel.setMigratedBalance(balance.holderAddress, balance.amount);
                balance.migrated = true;
            }

        }
    }

    function doSingleMigration(uint256 _id) public onlyOwner {
        require(_id < balances.length);
        Balance storage balance = balances[_id];
        require(false == balance.migrated);
        if (balance.amount > 0) {
            newCajutel.setMigratedBalance(balance.holderAddress, balance.amount);
            balance.migrated = true;
        }

    }

    function checkStatus(uint256 _id) public constant onlyOwner returns (bool){
        require(_id < balances.length);
        Balance storage balance = balances[_id];
        return balance.migrated;
    }
}