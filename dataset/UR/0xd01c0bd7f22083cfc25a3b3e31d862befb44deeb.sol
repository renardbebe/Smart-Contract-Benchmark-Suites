 

 
 
 

pragma solidity 0.4.24;

library Heap{  

  uint constant ROOT_INDEX = 1;

  struct Data{
    int128 idCount;
    Node[] nodes;  
    mapping (int128 => uint) indices;  
  }
  struct Node{
    int128 id;  
    int128 priority;
  }

   
  function init(Data storage self) internal{
    if(self.nodes.length == 0) self.nodes.push(Node(0,0));
  }

  function insert(Data storage self, int128 priority) internal returns(Node){ 
    if(self.nodes.length == 0){ init(self); } 
    self.idCount++;
    self.nodes.length++;
    Node memory n = Node(self.idCount, priority);
    _bubbleUp(self, n, self.nodes.length-1);
    return n;
  }
  function extractMax(Data storage self) internal returns(Node){ 
    return _extract(self, ROOT_INDEX);
  }
  function extractById(Data storage self, int128 id) internal returns(Node){ 
    return _extract(self, self.indices[id]);
  }

   
  function dump(Data storage self) internal view returns(Node[]){
   
    return self.nodes;
  }
  function getById(Data storage self, int128 id) internal view returns(Node){
    return getByIndex(self, self.indices[id]); 
  }
  function getByIndex(Data storage self, uint i) internal view returns(Node){
    return self.nodes.length > i ? self.nodes[i] : Node(0,0);
  }
  function getMax(Data storage self) internal view returns(Node){
    return getByIndex(self, ROOT_INDEX);
  }
  function size(Data storage self) internal view returns(uint){
    return self.nodes.length > 0 ? self.nodes.length-1 : 0;
  }
  function isNode(Node n) internal pure returns(bool){ return n.id > 0; }

   
  function _extract(Data storage self, uint i) private returns(Node){ 
    if(self.nodes.length <= i || i <= 0){ return Node(0,0); }

    Node memory extractedNode = self.nodes[i];
    delete self.indices[extractedNode.id];

    Node memory tailNode = self.nodes[self.nodes.length-1];
    self.nodes.length--;

    if(i < self.nodes.length){  
      _bubbleUp(self, tailNode, i);
      _bubbleDown(self, self.nodes[i], i);  
    }
    return extractedNode;
  }
  function _bubbleUp(Data storage self, Node memory n, uint i) private{ 
    if(i==ROOT_INDEX || n.priority <= self.nodes[i/2].priority){
      _insert(self, n, i);
    }else{
      _insert(self, self.nodes[i/2], i);
      _bubbleUp(self, n, i/2);
    }
  }
  function _bubbleDown(Data storage self, Node memory n, uint i) private{ 
    uint length = self.nodes.length;
    uint cIndex = i*2;  

    if(length <= cIndex){
      _insert(self, n, i);
    }else{
      Node memory largestChild = self.nodes[cIndex];

      if(length > cIndex+1 && self.nodes[cIndex+1].priority > largestChild.priority ){
        largestChild = self.nodes[++cIndex]; 
      }

      if(largestChild.priority <= n.priority){  
        _insert(self, n, i);
      }else{
        _insert(self, largestChild, i);
        _bubbleDown(self, n, cIndex);
      }
    }
  }

  function _insert(Data storage self, Node memory n, uint i) private{ 
    self.nodes[i] = n;
    self.indices[n.id] = i;
  }
}


contract BountyHeap{
  using Heap for Heap.Data;
  Heap.Data public data;

  uint public createdAt;
  address public author;

  constructor(address _author) public {
    data.init();
    createdAt = now;
    author = _author;
  }

  function () public payable{}

  function endBounty() public{
    require(now > createdAt + 2592000);  
    author.transfer(address(this).balance);  
  }

  function breakCompleteness(uint holeIndex, uint filledIndex, address recipient) public{
    require(holeIndex > 0);  
    require(data.getByIndex(holeIndex).id == 0);  
    require(data.getByIndex(filledIndex).id != 0);  
    require(holeIndex < filledIndex);  
    recipient.transfer(address(this).balance);
  }
  function breakParentsHaveGreaterPriority(uint indexChild, address recipient) public{
    Heap.Node memory child = data.getByIndex(indexChild);
    Heap.Node memory parent = data.getByIndex(indexChild/2);

    require(Heap.isNode(child));
    require(Heap.isNode(parent));
    require(child.priority > parent.priority);  
    recipient.transfer(address(this).balance);
  }
  function breakIdMaintenance(int128 id, address recipient) public{
    require(data.indices[id] != 0);  
    require(data.nodes[data.indices[id]].id != id);  
    recipient.transfer(address(this).balance);
  }
  function breakIdMaintenance2(uint index, address recipient) public{
    Heap.Node memory n = data.getByIndex(index);

    require(Heap.isNode(n));  
    require(index != data.indices[n.id]);  
    recipient.transfer(address(this).balance);
  }
  function breakIdUniqueness(uint index1, uint index2, address recipient) public{
    Heap.Node memory node1 = data.getByIndex(index1);
    Heap.Node memory node2 = data.getByIndex(index2);

    require(Heap.isNode(node1));
    require(Heap.isNode(node2));
    require(index1 != index2);      
    require(node1.id == node2.id);  
    recipient.transfer(address(this).balance);
  }

  function heapify(int128[] priorities) public {
    for(uint i ; i < priorities.length ; i++){
    data.insert(priorities[i]);
    }
  }
  function insert(int128 priority) public returns(int128){
    return data.insert(priority).id;
  }
  function extractMax() public returns(int128){
    return data.extractMax().priority;
  }
  function extractById(int128 id) public returns(int128){
    return data.extractById(id).priority;
  }
   
   
   
   
   
   
   
  function getIdMax() public view returns(int128){
    return data.getMax().id;
  }
  function getMax() public view returns(int128){
    return data.getMax().priority;
  }
  function getById(int128 id) public view returns(int128){
    return data.getById(id).priority;
  }
  function getIdByIndex(uint i) public view returns(int128){
    return data.getByIndex(i).id;
  }
  function getByIndex(uint i) public view returns(int128){
    return data.getByIndex(i).priority;
  }
  function size() public view returns(uint){
    return data.size();
  }
  function idCount() public view returns(int128){
    return data.idCount;
  }
  function indices(int128 id) public view returns(uint){
    return data.indices[id];
  }
}