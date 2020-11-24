 

pragma solidity >=0.4.21 <0.6.0;

contract SatoshiMoon {
    address public owner;
    address payable public admin1;
    address payable public admin2;
    address[] public addresses;

    uint public admin1Percent = 50;
    uint public admin2Percent = 50;

    uint public firstReferrerPercent = 20;
    uint public otherReferrerPercent = 5;

    mapping(address => Investor) investors;

    event Invest(address addr, uint amount, address referrer);
    event Referrer(address addr, address referrer);
    event Payout(address refferer, uint amount, address emitter);

    struct Investor {
        uint id;
        address referrer;
    }

    constructor() public {
        owner = msg.sender;
        addresses.length = 1;
    }

    function setAdmins(address _admin1, address _admin2) public onlyOwner {
        require(_admin1 != address(0), 'First admin is required');
        admin1 = address(uint160(address(_admin1)));
        admin2 = address(uint160(address(_admin2)));
    }

    function setAdminsPercent(uint _admin1Percent, uint _admin2Percent) public onlyOwner {
        admin1Percent = _admin1Percent;
        admin2Percent = _admin2Percent;
    }

    function getAdmins() public view returns (address, address) {
        return (admin1, admin2);
    }

    function setPercents(uint _firstPercent, uint _otherPercent) public onlyOwner {
        firstReferrerPercent = _firstPercent;
        otherReferrerPercent = _otherPercent;
    }

    function getPercents() public view returns (uint, uint, uint, uint) {
        return (admin1Percent, admin2Percent, firstReferrerPercent, otherReferrerPercent);
    }

    function() payable external {
        Investor storage user = investors[msg.sender];

        if (user.id == 0) {
             
            user.id = addresses.length;
            addresses.push(msg.sender);
            address ref = bytesToAddress(msg.data);
            if (investors[ref].id > 0 && ref != msg.sender) {
                user.referrer = ref;
                emit Referrer(msg.sender, user.referrer);
            }
        }

        emit Invest(msg.sender, msg.value, user.referrer);

        uint value = msg.value;
        address payable referrer = address(uint160(address(user.referrer)));
        for (uint i = 0; i < 7; i++) {
            if (referrer != address(0)) {
                uint txValue = i == 0 ? msg.value / 100 * firstReferrerPercent : msg.value / 100 * otherReferrerPercent;
                if (referrer.send(txValue)) {
                    emit Payout(referrer, txValue, msg.sender);
                    value -= txValue;
                }
                referrer = address(uint160(address(investors[referrer].referrer)));
            } else {
                break;
            }
        }

        if (admin2 != address(0)) {
            uint admin2Value = value / 100 * admin2Percent;
            admin2.transfer(admin2Value);
            emit Payout(admin2, admin2Value, msg.sender);
            value -= admin2Value;
        }

        admin1.transfer(value);
        emit Payout(admin1, value, msg.sender);
    }

    modifier onlyOwner {if (msg.sender == owner) _;}

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}