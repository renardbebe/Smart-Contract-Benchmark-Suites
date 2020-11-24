 

pragma solidity ^0.5.7;
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
contract Ownable {

  address public owner;
  address public manager;
  address public ownerWallet;

  constructor() public {
    owner = msg.sender;
    manager = msg.sender;
    ownerWallet = 0xB9adbfcA8309940Af83f6a2AE5eFffb9FcE779e9;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "only for owner");
    _;
  }

  modifier onlyOwnerOrManager() {
     require((msg.sender == owner)||(msg.sender == manager), "only for owner or manager");
      _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }

  function setManager(address _manager) public onlyOwnerOrManager {
      manager = _manager;
  }
}
contract CryptoFair is Ownable {
    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event buyLvEvent(address indexed _user, uint _level, uint _time);
    event prolongateLevelEvent(address indexed _user, uint _level, uint _time);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);
    event lostMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);
    mapping (uint => uint) public lvp;
    uint ref_1_lm = 3;
    uint prl = 365 days;
    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        address[] referral;
        mapping (uint => uint) lvExp;
    }
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    uint public currUserID = 0;
    constructor() public {
        lvp[1] = 0.08 ether;
        lvp[2] = 0.24 ether;
        lvp[3] = 0.72 ether;
        lvp[4] = 2.16 ether;
        lvp[5] = 6.48 ether;
        lvp[6] = 19.44 ether;
        lvp[7] = 58.32 ether;
        lvp[8] = 174.96 ether;
        UserStruct memory userStruct;
        currUserID++;
        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            referrerID : 0,
            referral : new address[](0)
        });
        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;
        users[ownerWallet].lvExp[1] = 77777777777;
        users[ownerWallet].lvExp[2] = 77777777777;
        users[ownerWallet].lvExp[3] = 77777777777;
        users[ownerWallet].lvExp[4] = 77777777777;
        users[ownerWallet].lvExp[5] = 77777777777;
        users[ownerWallet].lvExp[6] = 77777777777;
        users[ownerWallet].lvExp[7] = 77777777777;
        users[ownerWallet].lvExp[8] = 77777777777;
    }
    function () external payable {
        uint level;
        if(msg.value == lvp[1]){
            level = 1;
        }else if(msg.value == lvp[2]){
            level = 2;
        }else if(msg.value == lvp[3]){
            level = 3;
        }else if(msg.value == lvp[4]){
            level = 4;
        }else if(msg.value == lvp[5]){
            level = 5;
        }else if(msg.value == lvp[6]){
            level = 6;
        }else if(msg.value == lvp[7]){
            level = 7;
        }else if(msg.value == lvp[8]){
            level = 8;
        }else {
            revert('Incorrect Value send');
        }

        if(users[msg.sender].isExist){
            buyLv(level);
        } else if(level == 1) {
            uint refId = 0;
            address referrer = bytesToAddress(msg.data);

            if (users[referrer].isExist){
                refId = users[referrer].id;
            } else {
                revert('Incorrect referrer');
            }

            regUser(refId);
        } else {
            revert("Please buy first level for 0.05 ETH");
        }
    }
    function regUser(uint _referrerID) public payable {
        require(!users[msg.sender].isExist, 'User exist');
        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referrer Id');
        require(msg.value==lvp[1], 'Incorrect Value');
        if(users[userList[_referrerID]].referral.length >= ref_1_lm)
        {
            _referrerID = users[findRef(userList[_referrerID])].id;
        }
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            referrerID : _referrerID,
            referral : new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;

        users[msg.sender].lvExp[1] = now + prl;
        users[msg.sender].lvExp[2] = 0;
        users[msg.sender].lvExp[3] = 0;
        users[msg.sender].lvExp[4] = 0;
        users[msg.sender].lvExp[5] = 0;
        users[msg.sender].lvExp[6] = 0;
        users[msg.sender].lvExp[7] = 0;
        users[msg.sender].lvExp[8] = 0;
        users[userList[_referrerID]].referral.push(msg.sender);
        buyFLv(1, msg.sender);
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }
    function buyLv(uint _level) public payable {
        require(users[msg.sender].isExist, 'User not exist');
        require( _level>0 && _level<=8, 'Incorrect level');
        if(_level == 1){
            require(msg.value==lvp[1], 'Incorrect Value');
            users[msg.sender].lvExp[1] += prl;
        } else {
            require(msg.value==lvp[_level], 'Incorrect Value');
            for(uint l =_level-1; l>0; l-- ){
                require(users[msg.sender].lvExp[l] >= now, 'Buy the previous level');
            }
            if(users[msg.sender].lvExp[_level] == 0){
                users[msg.sender].lvExp[_level] = now + prl;
            } else {
                users[msg.sender].lvExp[_level] += prl;
            }
        }
        buyFLv(_level, msg.sender);
        emit buyLvEvent(msg.sender, _level, now);
    }
    function buyFLv(uint _level, address _user) internal {
        address referer;
        address referer1;
        address referer2;
        address referer3;
        if(_level == 1 || _level == 5){
            referer = userList[users[_user].referrerID];
        } else if(_level == 2 || _level == 6){
            referer1 = userList[users[_user].referrerID];
            referer = userList[users[referer1].referrerID];
        } else if(_level == 3 || _level == 7){
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer = userList[users[referer2].referrerID];
        } else if(_level == 4 || _level == 8){
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer3 = userList[users[referer2].referrerID];
            referer = userList[users[referer3].referrerID];
        }

        if(!users[referer].isExist){
            referer = userList[1];
        }

        if(users[referer].lvExp[_level] >= now ){
            bool result;
            result = address(uint160(referer)).send(lvp[_level]);
            emit getMoneyForLevelEvent(referer, msg.sender, _level, now);
        } else {
            emit lostMoneyForLevelEvent(referer, msg.sender, _level, now);
            buyFLv(_level,referer);
        }
    }

    function findRef(address _user) public view returns(address) {
        if(users[_user].referral.length < ref_1_lm){
            return _user;
        }
        address[] memory referrals = new address[](363);
        referrals[0] = users[_user].referral[0]; 
        referrals[1] = users[_user].referral[1];
        referrals[2] = users[_user].referral[2];
        address freeReferrer;
        bool noFreeReferrer = true;
        for(uint i =0; i<363;i++){
            if(users[referrals[i]].referral.length == ref_1_lm){
                if(i<120){
                    referrals[(i+1)*3] = users[referrals[i]].referral[0];
                    referrals[(i+1)*3+1] = users[referrals[i]].referral[1];
                    referrals[(i+1)*3+2] = users[referrals[i]].referral[2];
                }
            }else{
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        require(!noFreeReferrer, 'No Free Referrer');
        return freeReferrer;
    }

    function viewURef(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }

    function viewULvExp(address _user, uint _level) public view returns(uint) {
        return users[_user].lvExp[_level];
    }
    function bytesToAddress(bytes memory bys) private pure returns (address  addr ) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}