 

pragma solidity ^0.4.18;

 
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

contract ERC20Basic {
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
}

contract ReferTokenERC20Basic is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) rewardBalances;
    mapping(address => mapping(address => uint256)) allow;

    function _transfer(address _from, address _to, uint256 _value) private returns (bool) {
        require(_to != address(0));
        require(_value <= rewardBalances[_from]);

         
        rewardBalances[_from] = rewardBalances[_from].sub(_value);
        rewardBalances[_to] = rewardBalances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return rewardBalances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != msg.sender);
        require(allow[_from][msg.sender] > _value || allow[msg.sender][_to] == _value);

        success = _transfer(_from, _to, _value);

        if (success) {
            allow[_from][msg.sender] = allow[_from][msg.sender].sub(_value);
        }

        return success;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allow[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allow[_owner][_spender];
    }

}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract MintableToken is Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

contract PackageContract is ReferTokenERC20Basic, MintableToken {
    uint constant daysPerMonth = 30;
    mapping(uint => mapping(string => uint256)) internal packageType;

    struct Package {
        uint256 since;
        uint256 tokenValue;
        uint256 kindOf;
    }

    mapping(address => Package) internal userPackages;

    function PackageContract() public {
        packageType[2]['fee'] = 30;
        packageType[2]['reward'] = 20;
        packageType[4]['fee'] = 35;
        packageType[4]['reward'] = 25;
    }

    function depositMint(address _to, uint256 _amount, uint _kindOfPackage) canMint internal returns (bool) {
        return depositMintSince(_to, _amount, _kindOfPackage, now);
    }

    function depositMintSince(address _to, uint256 _amount, uint _kindOfPackage, uint since) canMint internal returns (bool) {
        totalSupply = totalSupply.add(_amount);
        Package memory pac;
        pac = Package({since : since, tokenValue : _amount, kindOf : _kindOfPackage});
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        userPackages[_to] = pac;
        return true;
    }

    function depositBalanceOf(address _owner) public view returns (uint256 balance) {
        return userPackages[_owner].tokenValue;
    }

    function getKindOfPackage(address _owner) public view returns (uint256) {
        return userPackages[_owner].kindOf;
    }

}

contract ColdWalletToken is PackageContract {
    address internal coldWalletAddress;
    uint internal percentageCW = 30;

    event CWStorageTransferred(address indexed previousCWAddress, address indexed newCWAddress);
    event CWPercentageChanged(uint previousPCW, uint newPCW);

    function setColdWalletAddress(address _newCWAddress) onlyOwner public {
        require(_newCWAddress != coldWalletAddress && _newCWAddress != address(0));
        CWStorageTransferred(coldWalletAddress, _newCWAddress);
        coldWalletAddress = _newCWAddress;
    }

    function getColdWalletAddress() onlyOwner public view returns (address) {
        return coldWalletAddress;
    }

    function setPercentageCW(uint _newPCW) onlyOwner public {
        require(_newPCW != percentageCW && _newPCW < 100);
        CWPercentageChanged(percentageCW, _newPCW);
        percentageCW = _newPCW;
    }

    function getPercentageCW() onlyOwner public view returns (uint) {
        return percentageCW;
    }

    function saveToCW() onlyOwner public {
        coldWalletAddress.transfer(this.balance.mul(percentageCW).div(100));
    }
}

contract StatusContract is Ownable {

    mapping(uint => mapping(string => uint[])) internal statusRewardsMap;
    mapping(address => uint) internal statuses;

    event StatusChanged(address participant, uint newStatus);

    function StatusContract() public {
        statusRewardsMap[1]['deposit'] = [3, 2, 1];
        statusRewardsMap[1]['refReward'] = [3, 1, 1];

        statusRewardsMap[2]['deposit'] = [7, 3, 1];
        statusRewardsMap[2]['refReward'] = [5, 3, 1];

        statusRewardsMap[3]['deposit'] = [10, 3, 1, 1, 1];
        statusRewardsMap[3]['refReward'] = [7, 3, 3, 1, 1];

        statusRewardsMap[4]['deposit'] = [10, 5, 3, 3, 1];
        statusRewardsMap[4]['refReward'] = [10, 5, 3, 3, 3];

        statusRewardsMap[5]['deposit'] = [12, 5, 3, 3, 3];
        statusRewardsMap[5]['refReward'] = [10, 7, 5, 3, 3];
    }

    function getStatusOf(address participant) public view returns (uint) {
        return statuses[participant];
    }

    function setStatus(address participant, uint8 status) public onlyOwner returns (bool) {
        return setStatusInternal(participant, status);
    }

    function setStatusInternal(address participant, uint8 status) internal returns (bool) {
        require(statuses[participant] != status && status > 0 && status <= 5);
        statuses[participant] = status;
        StatusChanged(participant, status);
        return true;
    }
}

contract ReferTreeContract is Ownable {
    mapping(address => address) public referTree;

    event TreeStructChanged(address sender, address parentSender);

    function checkTreeStructure(address sender, address parentSender) onlyOwner public {
        setTreeStructure(sender, parentSender);
    }

    function setTreeStructure(address sender, address parentSender) internal {
        require(referTree[sender] == 0x0);
        require(sender != parentSender);
        referTree[sender] = parentSender;
        TreeStructChanged(sender, parentSender);
    }
}

contract ReferToken is ColdWalletToken, StatusContract, ReferTreeContract {
    string public constant name = "EtherState";
    string public constant symbol = "ETHS";
    uint256 public constant decimals = 18;
    uint256 public totalSupply = 0;

    uint256 public constant hardCap = 10000000 * 1 ether;
    mapping(address => uint256) private lastPayoutAddress;
    uint private rate = 100;
    uint public constant depth = 5;

    event RateChanged(uint previousRate, uint newRate);
    event DataReceived(bytes data);
    event RefererAddressReceived(address referer);

    function depositMintAndPay(address _to, uint256 _amount, uint _kindOfPackage) canMint private returns (bool) {
        require(userPackages[_to].since == 0);
        _amount = _amount.mul(rate);
        if (depositMint(_to, _amount, _kindOfPackage)) {
            payToReferer(_to, _amount, 'deposit');
            lastPayoutAddress[_to] = now;
        }
    }

    function rewardMint(address _to, uint256 _amount) private returns (bool) {
        rewardBalances[_to] = rewardBalances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

    function payToReferer(address sender, uint256 _amount, string _key) private {
        address currentReferral = sender;
        uint currentStatus = 0;
        uint256 refValue = 0;

        for (uint level = 0; level < depth; ++level) {
            currentReferral = referTree[currentReferral];
            if (currentReferral == 0x0) {
                break;
            }
            currentStatus = statuses[currentReferral];
            if (currentStatus < 3 && level >= 3) {
                continue;
            }
            refValue = _amount.mul(statusRewardsMap[currentStatus][_key][level]).div(100);
            rewardMint(currentReferral, refValue);
        }
    }

    function AddressDailyReward(address rewarded) public {
        require(lastPayoutAddress[rewarded] != 0 && (now - lastPayoutAddress[rewarded]).div(1 days) > 0);
        uint256 n = (now - lastPayoutAddress[rewarded]).div(1 days);
        uint256 refValue = 0;

        if (userPackages[rewarded].kindOf != 0) {
            refValue = userPackages[rewarded].tokenValue.mul(n).mul(packageType[userPackages[rewarded].kindOf]['reward']).div(30).div(100);
            rewardMint(rewarded, refValue);
            payToReferer(rewarded, userPackages[rewarded].tokenValue, 'refReward');
        }
        if (n > 0) {
            lastPayoutAddress[rewarded] = now;
        }
    }

    function() external payable {
        require(totalSupply < hardCap);
        coldWalletAddress.transfer(msg.value.mul(percentageCW).div(100));
        bytes memory data = bytes(msg.data);
        DataReceived(data);
        address referer = getRefererAddress(data);
        RefererAddressReceived(referer);
        setTreeStructure(msg.sender, referer);
        setStatusInternal(msg.sender, 1);
        uint8 kind = getReferralPackageKind(data);
        depositMintAndPay(msg.sender, msg.value, kind);
    }

    function getRefererAddress(bytes data) private pure returns (address) {
        if (data.length == 1 || data.length == 0) {
            return address(0);
        }
        uint256 referer_address;
        uint256 factor = 1;
        for (uint i = 20; i > 0; i--) {
            referer_address += uint8(data[i - 1]) * factor;
            factor = factor * 256;
        }
        return address(referer_address);
    }

    function getReferralPackageKind(bytes data) private pure returns (uint8) {
        if (data.length == 0) {
            return 4;
        }
        if (data.length == 1) {
            return uint8(data[0]);
        }
        return uint8(data[20]);
    }

    function withdraw() public {
        require(userPackages[msg.sender].tokenValue != 0);
        uint256 withdrawValue = userPackages[msg.sender].tokenValue.div(rate);
        uint256 dateDiff = now - userPackages[msg.sender].since;
        if (dateDiff < userPackages[msg.sender].kindOf.mul(30 days)) {
            uint256 fee = withdrawValue.mul(packageType[userPackages[msg.sender].kindOf]['fee']).div(100);
            withdrawValue = withdrawValue.sub(fee);
            coldWalletAddress.transfer(fee);
            userPackages[msg.sender].tokenValue = 0;
        }
        msg.sender.transfer(withdrawValue);
    }

    function createRawDeposit(address sender, uint256 _value, uint d, uint since) onlyOwner public {
        depositMintSince(sender, _value, d, since);
    }

    function createDeposit(address sender, uint256 _value, uint d) onlyOwner public {
        depositMintAndPay(sender, _value, d);
    }

    function setRate(uint _newRate) onlyOwner public {
        require(_newRate != rate && _newRate > 0);
        RateChanged(rate, _newRate);
        rate = _newRate;
    }

    function getRate() public view returns (uint) {
        return rate;
    }
}