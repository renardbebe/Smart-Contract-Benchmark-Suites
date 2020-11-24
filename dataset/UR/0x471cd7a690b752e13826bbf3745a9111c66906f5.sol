 

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

contract Ethergarden is Ownable {
  using SafeMath for uint256;

  struct Tree {
    uint256 amount;
    string name;
    string url;
  }

  event NewTree(uint256 treeId, string name, string url, uint256 amount);
  event TreeWatered(uint256 treeId, uint256 amount);
  event TreeCutted(uint256 treeId, uint256 amount);
  event TreeUpdated(uint256 treeId, string name, string url);

  Tree[] public forest;
  mapping (uint256 => address) public treeToOwner;
  mapping (address => uint256) internal ownerTreeCount;

  function _createTree(string _name, string _url, uint256 _amount) private {
    uint256 id = forest.push(Tree(_amount, _name, _url)) - 1;
    treeToOwner[id] = msg.sender;
    ownerTreeCount[msg.sender] = ownerTreeCount[msg.sender].add(1);

    NewTree(id, _name, _url, _amount);
  }

  function createTree(string _name, string _url) payable external {
    require(msg.value >= 0.001 ether);

    _createTree(_name, _url, msg.value);
  }

  function getForestCount() external view returns(uint256) {
    return forest.length;
  }

  function changeTreeAttributes(uint256 _treeId, string _name, string _url) external {
    require(msg.sender == treeToOwner[_treeId]);

    Tree storage myTree = forest[_treeId];
    myTree.name = _name;
    myTree.url = _url;

    TreeUpdated(_treeId, myTree.name, myTree.url);
  }

  function dagheAcqua(uint256 _treeId) payable external {
    require(msg.value > 0.0001 ether);

    Tree storage myTree = forest[_treeId];
    myTree.amount = myTree.amount.add(msg.value);

    TreeWatered(_treeId, myTree.amount);
  }

  function cut(uint256 _treeId) payable external {
    require(msg.value > 0.0001 ether);

    Tree storage myTree = forest[_treeId];
    myTree.amount = myTree.amount.sub(msg.value);

    TreeCutted(_treeId, myTree.amount);
  }

  function withdraw() external onlyOwner {
    owner.transfer(this.balance);
  }
   
  function() public payable {}
}