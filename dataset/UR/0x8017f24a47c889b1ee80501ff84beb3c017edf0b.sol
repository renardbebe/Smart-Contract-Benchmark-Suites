 

 


 
 
library GroveLib {
         
        struct Index {
                bytes32 id;
                bytes32 name;
                bytes32 root;
                mapping (bytes32 => Node) nodes;
        }

        struct Node {
                bytes32 nodeId;
                bytes32 indexId;
                bytes32 id;
                int value;
                bytes32 parent;
                bytes32 left;
                bytes32 right;
                uint height;
        }

         
         
         
        function computeIndexId(address owner, bytes32 indexName) constant returns (bytes32) {
                return sha3(owner, indexName);
        }

         
         
         
        function computeNodeId(bytes32 indexId, bytes32 id) constant returns (bytes32) {
                return sha3(indexId, id);
        }

        function max(uint a, uint b) internal returns (uint) {
            if (a >= b) {
                return a;
            }
            return b;
        }

         
         
         
         
        function getNodeId(Index storage index, bytes32 nodeId) constant returns (bytes32) {
            return index.nodes[nodeId].id;
        }

         
         
         
        function getNodeIndexId(Index storage index, bytes32 nodeId) constant returns (bytes32) {
            return index.nodes[nodeId].indexId;
        }

         
         
         
        function getNodeValue(Index storage index, bytes32 nodeId) constant returns (int) {
            return index.nodes[nodeId].value;
        }

         
         
         
        function getNodeHeight(Index storage index, bytes32 nodeId) constant returns (uint) {
            return index.nodes[nodeId].height;
        }

         
         
         
        function getNodeParent(Index storage index, bytes32 nodeId) constant returns (bytes32) {
            return index.nodes[nodeId].parent;
        }

         
         
         
        function getNodeLeftChild(Index storage index, bytes32 nodeId) constant returns (bytes32) {
            return index.nodes[nodeId].left;
        }

         
         
         
        function getNodeRightChild(Index storage index, bytes32 nodeId) constant returns (bytes32) {
            return index.nodes[nodeId].right;
        }

         
         
         
        function getPreviousNode(Index storage index, bytes32 nodeId) constant returns (bytes32) {
            Node storage currentNode = index.nodes[nodeId];

            if (currentNode.nodeId == 0x0) {
                 
                return 0x0;
            }

            Node memory child;

            if (currentNode.left != 0x0) {
                 
                child = index.nodes[currentNode.left];

                while (child.right != 0) {
                    child = index.nodes[child.right];
                }
                return child.nodeId;
            }

            if (currentNode.parent != 0x0) {
                 
                 
                 
                Node storage parent = index.nodes[currentNode.parent];
                child = currentNode;

                while (true) {
                    if (parent.right == child.nodeId) {
                        return parent.nodeId;
                    }

                    if (parent.parent == 0x0) {
                        break;
                    }
                    child = parent;
                    parent = index.nodes[parent.parent];
                }
            }

             
            return 0x0;
        }

         
         
         
        function getNextNode(Index storage index, bytes32 nodeId) constant returns (bytes32) {
            Node storage currentNode = index.nodes[nodeId];

            if (currentNode.nodeId == 0x0) {
                 
                return 0x0;
            }

            Node memory child;

            if (currentNode.right != 0x0) {
                 
                child = index.nodes[currentNode.right];

                while (child.left != 0) {
                    child = index.nodes[child.left];
                }
                return child.nodeId;
            }

            if (currentNode.parent != 0x0) {
                 
                 
                Node storage parent = index.nodes[currentNode.parent];
                child = currentNode;

                while (true) {
                    if (parent.left == child.nodeId) {
                        return parent.nodeId;
                    }

                    if (parent.parent == 0x0) {
                        break;
                    }
                    child = parent;
                    parent = index.nodes[parent.parent];
                }

                 
            }

             
            return 0x0;
        }


         
         
         
         
        function insert(Index storage index, bytes32 id, int value) public {
                bytes32 nodeId = computeNodeId(index.id, id);

                if (index.nodes[nodeId].nodeId == nodeId) {
                     
                     
                     
                    if (index.nodes[nodeId].value == value) {
                        return;
                    }
                    remove(index, id);
                }

                uint leftHeight;
                uint rightHeight;

                bytes32 previousNodeId = 0x0;

                bytes32 rootNodeId = index.root;

                if (rootNodeId == 0x0) {
                    rootNodeId = nodeId;
                    index.root = nodeId;
                }
                Node storage currentNode = index.nodes[rootNodeId];

                 
                while (true) {
                    if (currentNode.indexId == 0x0) {
                         
                        currentNode.nodeId = nodeId;
                        currentNode.parent = previousNodeId;
                        currentNode.indexId = index.id;
                        currentNode.id = id;
                        currentNode.value = value;
                        break;
                    }

                     
                    previousNodeId = currentNode.nodeId;

                     
                    if (value >= currentNode.value) {
                        if (currentNode.right == 0x0) {
                            currentNode.right = nodeId;
                        }
                        currentNode = index.nodes[currentNode.right];
                        continue;
                    }

                     
                    if (currentNode.left == 0x0) {
                        currentNode.left = nodeId;
                    }
                    currentNode = index.nodes[currentNode.left];
                }

                 
                _rebalanceTree(index, currentNode.nodeId);
        }

         
         
         
        function exists(Index storage index, bytes32 id) constant returns (bool) {
            bytes32 nodeId = computeNodeId(index.id, id);
            return (index.nodes[nodeId].nodeId == nodeId);
        }

         
         
         
        function remove(Index storage index, bytes32 id) public {
            bytes32 nodeId = computeNodeId(index.id, id);
            
            Node storage replacementNode;
            Node storage parent;
            Node storage child;
            bytes32 rebalanceOrigin;

            Node storage nodeToDelete = index.nodes[nodeId];

            if (nodeToDelete.id != id) {
                 
                return;
            }

            if (nodeToDelete.left != 0x0 || nodeToDelete.right != 0x0) {
                 
                 
                if (nodeToDelete.left != 0x0) {
                     
                    replacementNode = index.nodes[getPreviousNode(index, nodeToDelete.nodeId)];
                }
                else {
                     
                    replacementNode = index.nodes[getNextNode(index, nodeToDelete.nodeId)];
                }
                 
                parent = index.nodes[replacementNode.parent];

                 
                 
                rebalanceOrigin = replacementNode.nodeId;

                 
                 
                 
                 
                if (parent.left == replacementNode.nodeId) {
                    parent.left = replacementNode.right;
                    if (replacementNode.right != 0x0) {
                        child = index.nodes[replacementNode.right];
                        child.parent = parent.nodeId;
                    }
                }
                if (parent.right == replacementNode.nodeId) {
                    parent.right = replacementNode.left;
                    if (replacementNode.left != 0x0) {
                        child = index.nodes[replacementNode.left];
                        child.parent = parent.nodeId;
                    }
                }

                 
                 
                 
                replacementNode.parent = nodeToDelete.parent;
                if (nodeToDelete.parent != 0x0) {
                    parent = index.nodes[nodeToDelete.parent];
                    if (parent.left == nodeToDelete.nodeId) {
                        parent.left = replacementNode.nodeId;
                    }
                    if (parent.right == nodeToDelete.nodeId) {
                        parent.right = replacementNode.nodeId;
                    }
                }
                else {
                     
                     
                    index.root = replacementNode.nodeId;
                }

                replacementNode.left = nodeToDelete.left;
                if (nodeToDelete.left != 0x0) {
                    child = index.nodes[nodeToDelete.left];
                    child.parent = replacementNode.nodeId;
                }

                replacementNode.right = nodeToDelete.right;
                if (nodeToDelete.right != 0x0) {
                    child = index.nodes[nodeToDelete.right];
                    child.parent = replacementNode.nodeId;
                }
            }
            else if (nodeToDelete.parent != 0x0) {
                 
                 
                parent = index.nodes[nodeToDelete.parent];

                if (parent.left == nodeToDelete.nodeId) {
                    parent.left = 0x0;
                }
                if (parent.right == nodeToDelete.nodeId) {
                    parent.right = 0x0;
                }

                 
                rebalanceOrigin = parent.nodeId;
            }
            else {
                 
                 
                index.root = 0x0;
            }

             
            nodeToDelete.id = 0x0;
            nodeToDelete.nodeId = 0x0;
            nodeToDelete.indexId = 0x0;
            nodeToDelete.value = 0;
            nodeToDelete.parent = 0x0;
            nodeToDelete.left = 0x0;
            nodeToDelete.right = 0x0;

             
            if (rebalanceOrigin != 0x0) {
                _rebalanceTree(index, rebalanceOrigin);
            }
        }

        bytes2 constant GT = ">";
        bytes2 constant LT = "<";
        bytes2 constant GTE = ">=";
        bytes2 constant LTE = "<=";
        bytes2 constant EQ = "==";

        function _compare(int left, bytes2 operator, int right) internal returns (bool) {
            if (operator == GT) {
                return (left > right);
            }
            if (operator == LT) {
                return (left < right);
            }
            if (operator == GTE) {
                return (left >= right);
            }
            if (operator == LTE) {
                return (left <= right);
            }
            if (operator == EQ) {
                return (left == right);
            }

             
            throw;
        }

        function _getMaximum(Index storage index, bytes32 nodeId) internal returns (int) {
                Node storage currentNode = index.nodes[nodeId];

                while (true) {
                    if (currentNode.right == 0x0) {
                        return currentNode.value;
                    }
                    currentNode = index.nodes[currentNode.right];
                }
        }

        function _getMinimum(Index storage index, bytes32 nodeId) internal returns (int) {
                Node storage currentNode = index.nodes[nodeId];

                while (true) {
                    if (currentNode.left == 0x0) {
                        return currentNode.value;
                    }
                    currentNode = index.nodes[currentNode.left];
                }
        }


         
         
         
        function query(Index storage index, bytes2 operator, int value) public returns (bytes32) {
                bytes32 rootNodeId = index.root;
                
                if (rootNodeId == 0x0) {
                     
                    return 0x0;
                }

                Node storage currentNode = index.nodes[rootNodeId];

                while (true) {
                    if (_compare(currentNode.value, operator, value)) {
                         
                         
                        if ((operator == LT) || (operator == LTE)) {
                             
                             
                            if (currentNode.right == 0x0) {
                                return currentNode.nodeId;
                            }
                            if (_compare(_getMinimum(index, currentNode.right), operator, value)) {
                                 
                                 
                                currentNode = index.nodes[currentNode.right];
                                continue;
                            }
                            return currentNode.nodeId;
                        }

                        if ((operator == GT) || (operator == GTE) || (operator == EQ)) {
                             
                             
                            if (currentNode.left == 0x0) {
                                return currentNode.nodeId;
                            }
                            if (_compare(_getMaximum(index, currentNode.left), operator, value)) {
                                currentNode = index.nodes[currentNode.left];
                                continue;
                            }
                            return currentNode.nodeId;
                        }
                    }

                    if ((operator == LT) || (operator == LTE)) {
                        if (currentNode.left == 0x0) {
                             
                             
                            return 0x0;
                        }
                        currentNode = index.nodes[currentNode.left];
                        continue;
                    }

                    if ((operator == GT) || (operator == GTE)) {
                        if (currentNode.right == 0x0) {
                             
                             
                            return 0x0;
                        }
                        currentNode = index.nodes[currentNode.right];
                        continue;
                    }

                    if (operator == EQ) {
                        if (currentNode.value < value) {
                            if (currentNode.right == 0x0) {
                                return 0x0;
                            }
                            currentNode = index.nodes[currentNode.right];
                            continue;
                        }

                        if (currentNode.value > value) {
                            if (currentNode.left == 0x0) {
                                return 0x0;
                            }
                            currentNode = index.nodes[currentNode.left];
                            continue;
                        }
                    }
                }
        }

        function _rebalanceTree(Index storage index, bytes32 nodeId) internal {
             
             
            Node storage currentNode = index.nodes[nodeId];

            while (true) {
                int balanceFactor = _getBalanceFactor(index, currentNode.nodeId);

                if (balanceFactor == 2) {
                     
                    if (_getBalanceFactor(index, currentNode.left) == -1) {
                         
                         
                         
                        _rotateLeft(index, currentNode.left);
                    }
                    _rotateRight(index, currentNode.nodeId);
                }

                if (balanceFactor == -2) {
                     
                    if (_getBalanceFactor(index, currentNode.right) == 1) {
                         
                         
                         
                        _rotateRight(index, currentNode.right);
                    }
                    _rotateLeft(index, currentNode.nodeId);
                }

                if ((-1 <= balanceFactor) && (balanceFactor <= 1)) {
                    _updateNodeHeight(index, currentNode.nodeId);
                }

                if (currentNode.parent == 0x0) {
                     
                     
                    break;
                }

                currentNode = index.nodes[currentNode.parent];
            }
        }

        function _getBalanceFactor(Index storage index, bytes32 nodeId) internal returns (int) {
                Node storage node = index.nodes[nodeId];

                return int(index.nodes[node.left].height) - int(index.nodes[node.right].height);
        }

        function _updateNodeHeight(Index storage index, bytes32 nodeId) internal {
                Node storage node = index.nodes[nodeId];

                node.height = max(index.nodes[node.left].height, index.nodes[node.right].height) + 1;
        }

        function _rotateLeft(Index storage index, bytes32 nodeId) internal {
            Node storage originalRoot = index.nodes[nodeId];

            if (originalRoot.right == 0x0) {
                 
                 
                throw;
            }

             
             
            Node storage newRoot = index.nodes[originalRoot.right];
            newRoot.parent = originalRoot.parent;

             
            originalRoot.right = 0x0;

            if (originalRoot.parent != 0x0) {
                 
                 
                Node storage parent = index.nodes[originalRoot.parent];

                 
                 
                if (parent.left == originalRoot.nodeId) {
                    parent.left = newRoot.nodeId;
                }
                if (parent.right == originalRoot.nodeId) {
                    parent.right = newRoot.nodeId;
                }
            }


            if (newRoot.left != 0) {
                 
                 
                Node storage leftChild = index.nodes[newRoot.left];
                originalRoot.right = leftChild.nodeId;
                leftChild.parent = originalRoot.nodeId;
            }

             
            originalRoot.parent = newRoot.nodeId;
            newRoot.left = originalRoot.nodeId;

            if (newRoot.parent == 0x0) {
                index.root = newRoot.nodeId;
            }

             
            _updateNodeHeight(index, originalRoot.nodeId);
            _updateNodeHeight(index, newRoot.nodeId);
        }

        function _rotateRight(Index storage index, bytes32 nodeId) internal {
            Node storage originalRoot = index.nodes[nodeId];

            if (originalRoot.left == 0x0) {
                 
                 
                throw;
            }

             
             
            Node storage newRoot = index.nodes[originalRoot.left];
            newRoot.parent = originalRoot.parent;

             
            originalRoot.left = 0x0;

            if (originalRoot.parent != 0x0) {
                 
                 
                Node storage parent = index.nodes[originalRoot.parent];

                if (parent.left == originalRoot.nodeId) {
                    parent.left = newRoot.nodeId;
                }
                if (parent.right == originalRoot.nodeId) {
                    parent.right = newRoot.nodeId;
                }
            }

            if (newRoot.right != 0x0) {
                Node storage rightChild = index.nodes[newRoot.right];
                originalRoot.left = newRoot.right;
                rightChild.parent = originalRoot.nodeId;
            }

             
            originalRoot.parent = newRoot.nodeId;
            newRoot.right = originalRoot.nodeId;

            if (newRoot.parent == 0x0) {
                index.root = newRoot.nodeId;
            }

             
            _updateNodeHeight(index, originalRoot.nodeId);
            _updateNodeHeight(index, newRoot.nodeId);
        }
}


 
 
contract Grove {
         
         
        mapping (bytes32 => GroveLib.Index) index_lookup;

         
        mapping (bytes32 => bytes32) node_to_index;

         
         
         
        function computeIndexId(address owner, bytes32 indexName) constant returns (bytes32) {
                return GroveLib.computeIndexId(owner, indexName);
        }

         
         
         
        function computeNodeId(bytes32 indexId, bytes32 id) constant returns (bytes32) {
                return GroveLib.computeNodeId(indexId, id);
        }

         
         
         
        function getIndexName(bytes32 indexId) constant returns (bytes32) {
            return index_lookup[indexId].name;
        }

         
         
        function getIndexRoot(bytes32 indexId) constant returns (bytes32) {
            return index_lookup[indexId].root;
        }


         
         
        function getNodeId(bytes32 nodeId) constant returns (bytes32) {
            return GroveLib.getNodeId(index_lookup[node_to_index[nodeId]], nodeId);
        }

         
         
        function getNodeIndexId(bytes32 nodeId) constant returns (bytes32) {
            return GroveLib.getNodeIndexId(index_lookup[node_to_index[nodeId]], nodeId);
        }

         
         
        function getNodeValue(bytes32 nodeId) constant returns (int) {
            return GroveLib.getNodeValue(index_lookup[node_to_index[nodeId]], nodeId);
        }

         
         
        function getNodeHeight(bytes32 nodeId) constant returns (uint) {
            return GroveLib.getNodeHeight(index_lookup[node_to_index[nodeId]], nodeId);
        }

         
         
        function getNodeParent(bytes32 nodeId) constant returns (bytes32) {
            return GroveLib.getNodeParent(index_lookup[node_to_index[nodeId]], nodeId);
        }

         
         
        function getNodeLeftChild(bytes32 nodeId) constant returns (bytes32) {
            return GroveLib.getNodeLeftChild(index_lookup[node_to_index[nodeId]], nodeId);
        }

         
         
        function getNodeRightChild(bytes32 nodeId) constant returns (bytes32) {
            return GroveLib.getNodeRightChild(index_lookup[node_to_index[nodeId]], nodeId);
        }

         
         
        function getPreviousNode(bytes32 nodeId) constant returns (bytes32) {
            return GroveLib.getPreviousNode(index_lookup[node_to_index[nodeId]], nodeId);
        }

         
         
        function getNextNode(bytes32 nodeId) constant returns (bytes32) {
            return GroveLib.getNextNode(index_lookup[node_to_index[nodeId]], nodeId);
        }

         
         
         
         
        function insert(bytes32 indexName, bytes32 id, int value) public {
                bytes32 indexId = computeIndexId(msg.sender, indexName);
                var index = index_lookup[indexId];

                if (index.name != indexName) {
                         
                        index.name = indexName;
                        index.id = indexId;
                }

                 
                node_to_index[computeNodeId(indexId, id)] = indexId;

                GroveLib.insert(index, id, value);
        }

         
         
         
        function exists(bytes32 indexId, bytes32 id) constant returns (bool) {
            return GroveLib.exists(index_lookup[indexId], id);
        }

         
         
         
        function remove(bytes32 indexName, bytes32 id) public {
            GroveLib.remove(index_lookup[computeIndexId(msg.sender, indexName)], id);
        }

         
         
         
        function query(bytes32 indexId, bytes2 operator, int value) public returns (bytes32) {
                return GroveLib.query(index_lookup[indexId], operator, value);
        }
}