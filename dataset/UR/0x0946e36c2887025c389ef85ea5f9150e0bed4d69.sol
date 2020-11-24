 

pragma solidity ^0.4.23;
 

library SafeMath {

  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    if (_a == 0) {
      return 0;
    }
    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a / _b;
  }
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Ownable {

  address public owner;
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );
  constructor() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract ERC20Basic {
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract BasicToken is Ownable,ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(msg.sender != owner);
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_from != owner);
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract KOL is StandardToken{
    using SafeMath for uint256;

    uint256 public constant TOKEN_DECIMALS = 18;

    string public name = "KOL Community Alliance";
    string public symbol = "KOL";
    uint256 public decimals = TOKEN_DECIMALS;
    uint256 public totalSupply = 21000000 *(10**uint256(TOKEN_DECIMALS));

    uint256 public totalSupplyed = 0;
    address public ethFundDeposit;

    uint16 public constant totalSuperNodes = 21;
    uint16 public constant totalNodes = 500;
    uint16 public constant halfSuperNodes = 11;
    uint16 public constant mostNodes = 335;
    uint16 public constant halfNodes = 251;
    uint16 public constant minSuperNodes = 15;
    uint16 public constant minNodes = 101;

    uint16 public constant most = 67;
    uint16 public constant half = 51;
    uint16 public constant less = 33;

    function construct() public {
        ethFundDeposit = msg.sender;
    }
    function setEthFundDeposit(address _ethFundDeposit) onlyOwner public {
        require(_ethFundDeposit != address(0));
        ethFundDeposit = _ethFundDeposit;
    }

    function transferETH() onlyOwner public {
        require(ethFundDeposit != address(0));
        require(address(this).balance != 0);
        require(ethFundDeposit.send(address(this).balance));
    }
    function isOwner() internal view returns(bool success) {
        if (msg.sender == owner) return true;
        return false;
    }
}

contract KOLVote is KOL {

    uint256 public constant totalNodeSupply = 5000000 *(10**uint256(TOKEN_DECIMALS));
    uint256 public constant totalUserSupply = 16000000 *(10**uint256(TOKEN_DECIMALS));
    uint256 public nodeSupplyed = 0;
    uint256 public userSupplyed = 0;

    uint256 public superNodesNum = 0;
    uint256 public nodesNum = 0;
    uint256 public dealTime =  3 days;
    uint256 public missionId = 0;

    mapping(address => bool) private isSuperNode;
    mapping(address => bool) private isNode;
    mapping(address => mapping(uint256 => bool)) private Voter;


    event MissionPassed(uint256 _missionId,bytes32 _name);
    event OfferingFinished(uint256 _missionId,uint256 _totalAmount,uint256 _length);
    event RecycleTokens(uint256 _missionId,uint256 _totalAmount);
    event NodeChanged(uint16 _type,address _oldNode,address _newNode);
    event MissionLaunched(bytes32 _name,uint256 _missionId,address _whoLaunch);
    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) internal {
      require(_value <= balances[owner]);
      require(_value <= totalSupply);
      balances[owner] = balances[owner].sub(_value);
      totalSupply = totalSupply.sub(_value);
      emit Burn(owner, _value);
      emit Transfer(owner, address(0), _value);
    }

    modifier onlySuperNode() {
      require(isSuperNode[msg.sender]);
        _;
    }
    modifier onlyNode() {
        require(isNode[msg.sender]);
        _;
    }
    modifier onlyNodes() {
        require(isSuperNode[msg.sender]||isNode[msg.sender]);
        _;
    }

    function setSuperNode(address superNodeAddress) onlyOwner public{
      require(!isSuperNode[superNodeAddress]);
      require(superNodesNum < totalSuperNodes);
      isSuperNode[superNodeAddress] = true;
      superNodesNum++;
    }

    function setNode(address nodeAddress) onlyOwner public{
      require(!isNode[nodeAddress]);
      require(nodesNum < totalNodes);
      isNode[nodeAddress] = true;
      nodesNum++;

    }

    function querySuperNode(address _addr) public view returns(bool){
      return(isSuperNode[_addr]);
    }
    function queryNode(address _addr) public view returns(bool){
      return(isNode[_addr]);
    }
     
     
     

    struct KolMission{
      address oldNode;
      address newNode;
      uint256 startTime;
      uint256 endTime;
      uint256 totalAmount;
      uint256 offeringAmount;
      bytes32 name;
      uint16 agreeNodes;
      uint16 refuseNodes;
      uint16 agreeSuperNodes;
      uint16 refuseSuperNodes;
      bool superPassed;
      bool nodePassed;
      bool done;
    }
    mapping (uint256 => KolMission) private missionList;

    struct KolOffering{
      address target;
      uint256 targetAmount;
    }
    KolOffering[] private kolOfferings;

    mapping(uint256 => KolOffering[]) private offeringList;

     
    function createKolMission(uint16 _type,bytes32 _name,uint256 _totalAmount,address _oldNode,address _newNode) onlyNodes public {
        bytes32 iName = _name;
        if (_type == 2){
          require(isSuperNode[msg.sender]);
          iName = "CHANGE NODE";
        }else if (_type == 3){
          iName = "CHANGE OWNER";
        }else if (_type == 1){
          require(isNode[msg.sender]);
          iName = "CHANGE SUPER NODE";
        }else if ((_type ==4)){
          require((_totalAmount + userSupplyed) <= totalUserSupply);
        }else if (_type ==6){
          require((_totalAmount + nodeSupplyed) <= totalNodeSupply);
          iName = "CREATION ISSUING";
        }else if (_type ==7){
          iName = "RECYCLE TOKEN FROM OWNER";
        }
        missionList[missionId] = KolMission(_oldNode,
                                            _newNode,
                                            uint256(now),
                                            uint256(now + dealTime),
                                            _totalAmount,
                                            0,
                                            iName,
                                            0,
                                            0,
                                            0,
                                            0,
                                            false,
                                            false,
                                            false);

        missionId++;
        emit MissionLaunched(iName,missionId-1,msg.sender);
    }
    function addKolOffering(uint256 _missionId,address _target,uint256 _targetAmount) onlyNodes public{
      require(missionList[_missionId].superPassed);
      require(!missionList[_missionId].done);
      if (missionList[_missionId].name == "CREATION ISSUING"){
        require(isNode[_target]||isSuperNode[_target]);
      }
      require(missionList[_missionId].offeringAmount.add(_targetAmount) <= missionList[_missionId].totalAmount);
      offeringList[_missionId].push(KolOffering(_target,_targetAmount));
      missionList[_missionId].offeringAmount = missionList[_missionId].offeringAmount.add(_targetAmount);

    }
    function missionPassed(uint256 _missionId) private {
      if ((missionList[_missionId].name != "CHANGE SUPER NODE") &&
              (missionList[_missionId].name != "CHANGE NODE") &&
              (missionList[_missionId].name != "CHANGE OWNER") &&
              (missionList[_missionId].name != "RECYCLE TOKEN FROM OWNER")){
          emit MissionPassed(_missionId,missionList[_missionId].name);
        }

    }
     
    function excuteAuto(uint256 _missionId) private {
      if ((missionList[_missionId].name == "CHANGE NODE") && missionList[_missionId].superPassed){
        require(isNode[missionList[_missionId].oldNode]);
        require(!isSuperNode[missionList[_missionId].newNode]);
        isNode[missionList[_missionId].oldNode] = false;
        isNode[missionList[_missionId].newNode] = true;
        missionList[_missionId].done = true;
        emit NodeChanged(2,missionList[_missionId].oldNode,missionList[_missionId].newNode);
      }else if ((missionList[_missionId].name == "CHANGE SUPER NODE") && missionList[_missionId].nodePassed){
        require(isSuperNode[missionList[_missionId].oldNode]);
        require(!isSuperNode[missionList[_missionId].newNode]);
        isSuperNode[missionList[_missionId].oldNode] = false;
        isSuperNode[missionList[_missionId].newNode] = true;
        missionList[_missionId].done = true;
        emit NodeChanged(1,missionList[_missionId].oldNode,missionList[_missionId].newNode);
      }else if ((missionList[_missionId].name == "CHANGE OWNER") && missionList[_missionId].nodePassed){
        emit NodeChanged(3,owner,missionList[_missionId].newNode);
        _transferOwnership(missionList[_missionId].newNode);
        missionList[_missionId].done = true;
      }else if ((missionList[_missionId].name == "RECYCLE TOKEN FROM OWNER") && missionList[_missionId].nodePassed){
        burn(missionList[_missionId].totalAmount);
        emit RecycleTokens(_missionId,missionList[_missionId].totalAmount);
        missionList[_missionId].done = true;
      }
    }
     
    function voteMission(uint16 _type,uint256 _missionId,bool _agree) onlyNodes public{
      require(!Voter[msg.sender][_missionId]);
      require(!missionList[_missionId].done);
      uint16 minNodesNum = minNodes;
      uint16 minSuperNodesNum = minSuperNodes;
      uint16 passNodes = halfNodes;
      uint16 passSuperNodes = halfSuperNodes;
      uint16 rate = half;
      if (missionList[_missionId].name == "CHANGE OWNER") {
        rate = most;
        minNodesNum = totalNodes;
        passNodes = mostNodes;
      }else if (missionList[_missionId].name == "CHANGE NODE"){
        rate = less;
        minSuperNodesNum = minSuperNodes;
        passSuperNodes = halfSuperNodes;
      }else if (missionList[_missionId].name == "CHANGE SUPER NODE"){
        rate = less;
        minNodesNum = minNodes;
        passNodes = halfNodes;
      }else if (missionList[_missionId].name == "CREATION ISSUING"){
        minNodesNum = minNodes;
        passNodes = halfNodes;
        minSuperNodesNum = minSuperNodes;
        passSuperNodes = halfSuperNodes;
      }else if (missionList[_missionId].name == "RECYCLE TOKEN FROM OWNER"){
        minNodesNum = minNodes;
        passNodes = halfNodes;
      }

      if (_type == 1){
        require(isSuperNode[msg.sender]);
      }else if (_type ==2){
        require(isNode[msg.sender]);
      }

      if(now > missionList[_missionId].endTime){
        if ( _type == 1 ){
          if (
            (missionList[_missionId].agreeSuperNodes + missionList[_missionId].refuseSuperNodes)>=minSuperNodesNum
            &&
            missionList[_missionId].agreeSuperNodes >= (missionList[_missionId].agreeSuperNodes + missionList[_missionId].refuseSuperNodes) * rate/100
            ){
              missionList[_missionId].superPassed = true;
              missionPassed(_missionId);
          }
        }else if (_type ==2 ){
           
          if (
            (missionList[_missionId].agreeNodes + missionList[_missionId].refuseNodes)>=minNodesNum
            &&
            missionList[_missionId].agreeNodes >= (missionList[_missionId].refuseNodes + missionList[_missionId].refuseNodes) * rate/100
            ){
              missionList[_missionId].nodePassed = true;
          }
        }
      }else{
        if(_agree == true){
          if (_type == 1){
            missionList[_missionId].agreeSuperNodes++;
          }else if(_type == 2){
            missionList[_missionId].agreeNodes++;
          }
        }
        else{
          if (_type == 1){
            missionList[_missionId].refuseSuperNodes++;
          }else if(_type == 2){
            missionList[_missionId].refuseNodes++;
          }
        }
        if (_type == 1){
          if (missionList[_missionId].agreeSuperNodes >= passSuperNodes) {
              missionList[_missionId].superPassed = true;
              missionPassed(_missionId);
          }else if (missionList[_missionId].refuseSuperNodes >= passSuperNodes) {
              missionList[_missionId].done = true;
          }
        }else if (_type ==2){
          if (missionList[_missionId].agreeNodes >= passNodes) {
              missionList[_missionId].nodePassed = true;
          }else if (missionList[_missionId].refuseNodes >= passNodes) {
              missionList[_missionId].done = true;
          }
        }
      }
      Voter[msg.sender][_missionId] = true;
      excuteAuto(_missionId);
    }

    function excuteVote(uint256 _missionId) onlyOwner public {
      require(!missionList[_missionId].done);
      require(uint256(now) < (missionList[_missionId].endTime + uint256(dealTime)));

      require(missionList[_missionId].superPassed);
      require(missionList[_missionId].nodePassed);
      require(missionList[_missionId].totalAmount == missionList[_missionId].offeringAmount);
      require((missionList[_missionId].totalAmount.add(totalSupplyed))<=totalNodeSupply.add(totalUserSupply));

      if (missionList[_missionId].name == "CREATION ISSUING"){
        require((nodeSupplyed.add(missionList[_missionId].totalAmount))<=totalNodeSupply);
      }else{
        require((userSupplyed.add(missionList[_missionId].totalAmount))<=totalUserSupply);
      }
      for (uint m = 0; m < offeringList[_missionId].length; m++){
        balances[offeringList[_missionId][m].target] = balances[offeringList[_missionId][m].target].add(offeringList[_missionId][m].targetAmount);
        emit Transfer(msg.sender,offeringList[_missionId][m].target,offeringList[_missionId][m].targetAmount);
      }
      totalSupplyed = totalSupplyed.add(missionList[_missionId].totalAmount);

      if (missionList[_missionId].name == "CREATION ISSUING"){
        nodeSupplyed = nodeSupplyed.add(missionList[_missionId].totalAmount);
      }else{
        userSupplyed = userSupplyed.add(missionList[_missionId].totalAmount);
      }
      missionList[_missionId].done = true;
      emit OfferingFinished(_missionId,missionList[_missionId].offeringAmount,offeringList[_missionId].length);

    }
    function getMission1(uint256 _missionId) public view returns(address,
                                                              address,
                                                              uint256,
                                                              uint256,
                                                              uint256,
                                                              uint256,
                                                              bytes32){
      return(missionList[_missionId].oldNode,
              missionList[_missionId].newNode,
              missionList[_missionId].startTime,
              missionList[_missionId].endTime,
              missionList[_missionId].totalAmount,
              missionList[_missionId].offeringAmount,
              missionList[_missionId].name);
    }
    function getMission2(uint256 _missionId) public view returns(uint16,
                                                                uint16,
                                                                uint16,
                                                                uint16,
                                                                bool,
                                                                bool,
                                                                bool){
      return(
            missionList[_missionId].agreeNodes,
            missionList[_missionId].refuseNodes,
            missionList[_missionId].agreeSuperNodes,
            missionList[_missionId].refuseSuperNodes,
            missionList[_missionId].superPassed,
            missionList[_missionId].nodePassed,
            missionList[_missionId].done);
    }
    function getOfferings(uint256 _missionId,uint256 _id) public view returns(address,uint256,uint256){
      return(offeringList[_missionId][_id].target,offeringList[_missionId][_id].targetAmount,offeringList[_missionId].length);
    }
    function voted(address _node,uint256 _missionId) public view returns(bool){
      return Voter[_node][_missionId];
    }
}