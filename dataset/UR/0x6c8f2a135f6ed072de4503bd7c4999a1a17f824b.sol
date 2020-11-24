 

 


 
 
library GroveLib {
         
        struct Index {
                bytes32 root;
                mapping (bytes32 => Node) nodes;
        }

        struct Node {
                bytes32 id;
                int value;
                bytes32 parent;
                bytes32 left;
                bytes32 right;
                uint height;
        }

        function max(uint a, uint b) internal returns (uint) {
            if (a >= b) {
                return a;
            }
            return b;
        }

         
         
         
         
        function getNodeId(Index storage index, bytes32 id) constant returns (bytes32) {
            return index.nodes[id].id;
        }

         
         
         
        function getNodeValue(Index storage index, bytes32 id) constant returns (int) {
            return index.nodes[id].value;
        }

         
         
         
        function getNodeHeight(Index storage index, bytes32 id) constant returns (uint) {
            return index.nodes[id].height;
        }

         
         
         
        function getNodeParent(Index storage index, bytes32 id) constant returns (bytes32) {
            return index.nodes[id].parent;
        }

         
         
         
        function getNodeLeftChild(Index storage index, bytes32 id) constant returns (bytes32) {
            return index.nodes[id].left;
        }

         
         
         
        function getNodeRightChild(Index storage index, bytes32 id) constant returns (bytes32) {
            return index.nodes[id].right;
        }

         
         
         
        function getPreviousNode(Index storage index, bytes32 id) constant returns (bytes32) {
            Node storage currentNode = index.nodes[id];

            if (currentNode.id == 0x0) {
                 
                return 0x0;
            }

            Node memory child;

            if (currentNode.left != 0x0) {
                 
                child = index.nodes[currentNode.left];

                while (child.right != 0) {
                    child = index.nodes[child.right];
                }
                return child.id;
            }

            if (currentNode.parent != 0x0) {
                 
                 
                 
                Node storage parent = index.nodes[currentNode.parent];
                child = currentNode;

                while (true) {
                    if (parent.right == child.id) {
                        return parent.id;
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

         
         
         
        function getNextNode(Index storage index, bytes32 id) constant returns (bytes32) {
            Node storage currentNode = index.nodes[id];

            if (currentNode.id == 0x0) {
                 
                return 0x0;
            }

            Node memory child;

            if (currentNode.right != 0x0) {
                 
                child = index.nodes[currentNode.right];

                while (child.left != 0) {
                    child = index.nodes[child.left];
                }
                return child.id;
            }

            if (currentNode.parent != 0x0) {
                 
                 
                Node storage parent = index.nodes[currentNode.parent];
                child = currentNode;

                while (true) {
                    if (parent.left == child.id) {
                        return parent.id;
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
                if (index.nodes[id].id == id) {
                     
                     
                     
                    if (index.nodes[id].value == value) {
                        return;
                    }
                    remove(index, id);
                }

                uint leftHeight;
                uint rightHeight;

                bytes32 previousNodeId = 0x0;

                if (index.root == 0x0) {
                    index.root = id;
                }
                Node storage currentNode = index.nodes[index.root];

                 
                while (true) {
                    if (currentNode.id == 0x0) {
                         
                        currentNode.id = id;
                        currentNode.parent = previousNodeId;
                        currentNode.value = value;
                        break;
                    }

                     
                    previousNodeId = currentNode.id;

                     
                    if (value >= currentNode.value) {
                        if (currentNode.right == 0x0) {
                            currentNode.right = id;
                        }
                        currentNode = index.nodes[currentNode.right];
                        continue;
                    }

                     
                    if (currentNode.left == 0x0) {
                        currentNode.left = id;
                    }
                    currentNode = index.nodes[currentNode.left];
                }

                 
                _rebalanceTree(index, currentNode.id);
        }

         
         
         
        function exists(Index storage index, bytes32 id) constant returns (bool) {
            return (index.nodes[id].height > 0);
        }

         
         
         
        function remove(Index storage index, bytes32 id) public {
            Node storage replacementNode;
            Node storage parent;
            Node storage child;
            bytes32 rebalanceOrigin;

            Node storage nodeToDelete = index.nodes[id];

            if (nodeToDelete.id != id) {
                 
                return;
            }

            if (nodeToDelete.left != 0x0 || nodeToDelete.right != 0x0) {
                 
                 
                if (nodeToDelete.left != 0x0) {
                     
                    replacementNode = index.nodes[getPreviousNode(index, nodeToDelete.id)];
                }
                else {
                     
                    replacementNode = index.nodes[getNextNode(index, nodeToDelete.id)];
                }
                 
                parent = index.nodes[replacementNode.parent];

                 
                 
                rebalanceOrigin = replacementNode.id;

                 
                 
                 
                 
                if (parent.left == replacementNode.id) {
                    parent.left = replacementNode.right;
                    if (replacementNode.right != 0x0) {
                        child = index.nodes[replacementNode.right];
                        child.parent = parent.id;
                    }
                }
                if (parent.right == replacementNode.id) {
                    parent.right = replacementNode.left;
                    if (replacementNode.left != 0x0) {
                        child = index.nodes[replacementNode.left];
                        child.parent = parent.id;
                    }
                }

                 
                 
                 
                replacementNode.parent = nodeToDelete.parent;
                if (nodeToDelete.parent != 0x0) {
                    parent = index.nodes[nodeToDelete.parent];
                    if (parent.left == nodeToDelete.id) {
                        parent.left = replacementNode.id;
                    }
                    if (parent.right == nodeToDelete.id) {
                        parent.right = replacementNode.id;
                    }
                }
                else {
                     
                     
                    index.root = replacementNode.id;
                }

                replacementNode.left = nodeToDelete.left;
                if (nodeToDelete.left != 0x0) {
                    child = index.nodes[nodeToDelete.left];
                    child.parent = replacementNode.id;
                }

                replacementNode.right = nodeToDelete.right;
                if (nodeToDelete.right != 0x0) {
                    child = index.nodes[nodeToDelete.right];
                    child.parent = replacementNode.id;
                }
            }
            else if (nodeToDelete.parent != 0x0) {
                 
                 
                parent = index.nodes[nodeToDelete.parent];

                if (parent.left == nodeToDelete.id) {
                    parent.left = 0x0;
                }
                if (parent.right == nodeToDelete.id) {
                    parent.right = 0x0;
                }

                 
                rebalanceOrigin = parent.id;
            }
            else {
                 
                 
                index.root = 0x0;
            }

             
            nodeToDelete.id = 0x0;
            nodeToDelete.value = 0;
            nodeToDelete.parent = 0x0;
            nodeToDelete.left = 0x0;
            nodeToDelete.right = 0x0;
            nodeToDelete.height = 0;

             
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

        function _getMaximum(Index storage index, bytes32 id) internal returns (int) {
                Node storage currentNode = index.nodes[id];

                while (true) {
                    if (currentNode.right == 0x0) {
                        return currentNode.value;
                    }
                    currentNode = index.nodes[currentNode.right];
                }
        }

        function _getMinimum(Index storage index, bytes32 id) internal returns (int) {
                Node storage currentNode = index.nodes[id];

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
                                return currentNode.id;
                            }
                            if (_compare(_getMinimum(index, currentNode.right), operator, value)) {
                                 
                                 
                                currentNode = index.nodes[currentNode.right];
                                continue;
                            }
                            return currentNode.id;
                        }

                        if ((operator == GT) || (operator == GTE) || (operator == EQ)) {
                             
                             
                            if (currentNode.left == 0x0) {
                                return currentNode.id;
                            }
                            if (_compare(_getMaximum(index, currentNode.left), operator, value)) {
                                currentNode = index.nodes[currentNode.left];
                                continue;
                            }
                            return currentNode.id;
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

        function _rebalanceTree(Index storage index, bytes32 id) internal {
             
             
            Node storage currentNode = index.nodes[id];

            while (true) {
                int balanceFactor = _getBalanceFactor(index, currentNode.id);

                if (balanceFactor == 2) {
                     
                    if (_getBalanceFactor(index, currentNode.left) == -1) {
                         
                         
                         
                        _rotateLeft(index, currentNode.left);
                    }
                    _rotateRight(index, currentNode.id);
                }

                if (balanceFactor == -2) {
                     
                    if (_getBalanceFactor(index, currentNode.right) == 1) {
                         
                         
                         
                        _rotateRight(index, currentNode.right);
                    }
                    _rotateLeft(index, currentNode.id);
                }

                if ((-1 <= balanceFactor) && (balanceFactor <= 1)) {
                    _updateNodeHeight(index, currentNode.id);
                }

                if (currentNode.parent == 0x0) {
                     
                     
                    break;
                }

                currentNode = index.nodes[currentNode.parent];
            }
        }

        function _getBalanceFactor(Index storage index, bytes32 id) internal returns (int) {
                Node storage node = index.nodes[id];

                return int(index.nodes[node.left].height) - int(index.nodes[node.right].height);
        }

        function _updateNodeHeight(Index storage index, bytes32 id) internal {
                Node storage node = index.nodes[id];

                node.height = max(index.nodes[node.left].height, index.nodes[node.right].height) + 1;
        }

        function _rotateLeft(Index storage index, bytes32 id) internal {
            Node storage originalRoot = index.nodes[id];

            if (originalRoot.right == 0x0) {
                 
                 
                throw;
            }

             
             
            Node storage newRoot = index.nodes[originalRoot.right];
            newRoot.parent = originalRoot.parent;

             
            originalRoot.right = 0x0;

            if (originalRoot.parent != 0x0) {
                 
                 
                Node storage parent = index.nodes[originalRoot.parent];

                 
                 
                if (parent.left == originalRoot.id) {
                    parent.left = newRoot.id;
                }
                if (parent.right == originalRoot.id) {
                    parent.right = newRoot.id;
                }
            }


            if (newRoot.left != 0) {
                 
                 
                Node storage leftChild = index.nodes[newRoot.left];
                originalRoot.right = leftChild.id;
                leftChild.parent = originalRoot.id;
            }

             
            originalRoot.parent = newRoot.id;
            newRoot.left = originalRoot.id;

            if (newRoot.parent == 0x0) {
                index.root = newRoot.id;
            }

             
            _updateNodeHeight(index, originalRoot.id);
            _updateNodeHeight(index, newRoot.id);
        }

        function _rotateRight(Index storage index, bytes32 id) internal {
            Node storage originalRoot = index.nodes[id];

            if (originalRoot.left == 0x0) {
                 
                 
                throw;
            }

             
             
            Node storage newRoot = index.nodes[originalRoot.left];
            newRoot.parent = originalRoot.parent;

             
            originalRoot.left = 0x0;

            if (originalRoot.parent != 0x0) {
                 
                 
                Node storage parent = index.nodes[originalRoot.parent];

                if (parent.left == originalRoot.id) {
                    parent.left = newRoot.id;
                }
                if (parent.right == originalRoot.id) {
                    parent.right = newRoot.id;
                }
            }

            if (newRoot.right != 0x0) {
                Node storage rightChild = index.nodes[newRoot.right];
                originalRoot.left = newRoot.right;
                rightChild.parent = originalRoot.id;
            }

             
            originalRoot.parent = newRoot.id;
            newRoot.right = originalRoot.id;

            if (newRoot.parent == 0x0) {
                index.root = newRoot.id;
            }

             
            _updateNodeHeight(index, originalRoot.id);
            _updateNodeHeight(index, newRoot.id);
        }
}


 

 
 
library AccountingLib {
         
        struct Bank {
            mapping (address => uint) accountBalances;
        }

         
         
         
         
        function addFunds(Bank storage self, address accountAddress, uint value) public {
                if (self.accountBalances[accountAddress] + value < self.accountBalances[accountAddress]) {
                         
                        throw;
                }
                self.accountBalances[accountAddress] += value;
        }

        event _Deposit(address indexed _from, address indexed accountAddress, uint value);
         
         
         
         
        function Deposit(address _from, address accountAddress, uint value) public {
            _Deposit(_from, accountAddress, value);
        }


         
         
         
         
        function deposit(Bank storage self, address accountAddress, uint value) public returns (bool) {
                addFunds(self, accountAddress, value);
                return true;
        }

        event _Withdrawal(address indexed accountAddress, uint value);

         
         
         
        function Withdrawal(address accountAddress, uint value) public {
            _Withdrawal(accountAddress, value);
        }

        event _InsufficientFunds(address indexed accountAddress, uint value, uint balance);

         
         
         
         
        function InsufficientFunds(address accountAddress, uint value, uint balance) public {
            _InsufficientFunds(accountAddress, value, balance);
        }

         
         
         
         
        function deductFunds(Bank storage self, address accountAddress, uint value) public {
                 
                if (value > self.accountBalances[accountAddress]) {
                         
                        throw;
                }
                self.accountBalances[accountAddress] -= value;
        }

         
         
         
         
        function withdraw(Bank storage self, address accountAddress, uint value) public returns (bool) {
                 
                if (self.accountBalances[accountAddress] >= value) {
                        deductFunds(self, accountAddress, value);
                        if (!accountAddress.send(value)) {
                                 
                                 
                                 
                                if (!accountAddress.call.value(value)()) {
                                         
                                         
                                        throw;
                                }
                        }
                        return true;
                }
                return false;
        }

        uint constant DEFAULT_SEND_GAS = 100000;

        function sendRobust(address toAddress, uint value) public returns (bool) {
                if (msg.gas < DEFAULT_SEND_GAS) {
                    return sendRobust(toAddress, value, msg.gas);
                }
                return sendRobust(toAddress, value, DEFAULT_SEND_GAS);
        }

        function sendRobust(address toAddress, uint value, uint maxGas) public returns (bool) {
                if (value > 0 && !toAddress.send(value)) {
                         
                         
                         
                        if (!toAddress.call.gas(maxGas).value(value)()) {
                                return false;
                        }
                }
                return true;
        }
}


library CallLib {
     
    struct Call {
        address contractAddress;
        bytes4 abiSignature;
        bytes callData;
        uint callValue;
        uint anchorGasPrice;
        uint requiredGas;
        uint16 requiredStackDepth;

        address claimer;
        uint claimAmount;
        uint claimerDeposit;

        bool wasSuccessful;
        bool wasCalled;
        bool isCancelled;
    }

    enum State {
        Pending,
        Unclaimed,
        Claimed,
        Frozen,
        Callable,
        Executed,
        Cancelled,
        Missed
    }

    function state(Call storage self) constant returns (State) {
        if (self.isCancelled) return State.Cancelled;
        if (self.wasCalled) return State.Executed;

        var call = FutureBlockCall(this);

        if (block.number + CLAIM_GROWTH_WINDOW + MAXIMUM_CLAIM_WINDOW + BEFORE_CALL_FREEZE_WINDOW < call.targetBlock()) return State.Pending;
        if (block.number + BEFORE_CALL_FREEZE_WINDOW < call.targetBlock()) {
            if (self.claimer == 0x0) {
                return State.Unclaimed;
            }
            else {
                return State.Claimed;
            }
        }
        if (block.number < call.targetBlock()) return State.Frozen;
        if (block.number < call.targetBlock() + call.gracePeriod()) return State.Callable;
        return State.Missed;
    }

     
     
    uint constant CALL_WINDOW_SIZE = 16;

    address constant creator = 0xd3cda913deb6f67967b99d67acdfa1712c293601;

    function extractCallData(Call storage call, bytes data) public {
        call.callData.length = data.length - 4;
        if (data.length > 4) {
                for (uint i = 0; i < call.callData.length; i++) {
                        call.callData[i] = data[i + 4];
                }
        }
    }

    uint constant GAS_PER_DEPTH = 700;

    function checkDepth(uint n) constant returns (bool) {
        if (n == 0) return true;
        return address(this).call.gas(GAS_PER_DEPTH * n)(bytes4(sha3("__dig(uint256)")), n - 1);
    }

    function sendSafe(address to_address, uint value) public returns (uint) {
        if (value > address(this).balance) {
            value = address(this).balance;
        }
        if (value > 0) {
            AccountingLib.sendRobust(to_address, value);
            return value;
        }
        return 0;
    }

    function getGasScalar(uint base_gas_price, uint gas_price) constant returns (uint) {
         
        if (gas_price > base_gas_price) {
            return 100 * base_gas_price / gas_price;
        }
        else {
            return 200 - 100 * base_gas_price / (2 * base_gas_price - gas_price);
        }
    }

    event CallExecuted(address indexed executor, uint gasCost, uint payment, uint donation, bool success);

    bytes4 constant EMPTY_SIGNATURE = 0x0000;

    event CallAborted(address executor, bytes32 reason);

    function execute(Call storage self,
                     uint start_gas,
                     address executor,
                     uint overhead,
                     uint extraGas) public {
        FutureCall call = FutureCall(this);

         
        self.wasCalled = true;

         
        if (self.abiSignature == EMPTY_SIGNATURE && self.callData.length == 0) {
            self.wasSuccessful = self.contractAddress.call.value(self.callValue).gas(msg.gas - overhead)();
        }
        else if (self.abiSignature == EMPTY_SIGNATURE) {
            self.wasSuccessful = self.contractAddress.call.value(self.callValue).gas(msg.gas - overhead)(self.callData);
        }
        else if (self.callData.length == 0) {
            self.wasSuccessful = self.contractAddress.call.value(self.callValue).gas(msg.gas - overhead)(self.abiSignature);
        }
        else {
            self.wasSuccessful = self.contractAddress.call.value(self.callValue).gas(msg.gas - overhead)(self.abiSignature, self.callData);
        }

        call.origin().call(bytes4(sha3("updateDefaultPayment()")));

         
        uint gasScalar = getGasScalar(self.anchorGasPrice, tx.gasprice);

        uint basePayment;
        if (self.claimer == executor) {
            basePayment = self.claimAmount;
        }
        else {
            basePayment = call.basePayment();
        }
        uint payment = self.claimerDeposit + basePayment * gasScalar / 100;
        uint donation = call.baseDonation() * gasScalar / 100;

         
        self.claimerDeposit = 0;

         
         
         
        uint gasCost = tx.gasprice * (start_gas - msg.gas + extraGas);

         
        payment = sendSafe(executor, payment + gasCost);
        donation = sendSafe(creator, donation);

         
        CallExecuted(executor, gasCost, payment, donation, self.wasSuccessful);
    }

    event Cancelled(address indexed cancelled_by);

    function cancel(Call storage self, address sender) public {
        Cancelled(sender);
        if (self.claimerDeposit >= 0) {
            sendSafe(self.claimer, self.claimerDeposit);
        }
        var call = FutureCall(this);
        sendSafe(call.schedulerAddress(), address(this).balance);
        self.isCancelled = true;
    }

     
    event Claimed(address executor, uint claimAmount);

     
     
    uint constant CLAIM_GROWTH_WINDOW = 240;

     
     
    uint constant MAXIMUM_CLAIM_WINDOW = 15;

     
     
     
    uint constant BEFORE_CALL_FREEZE_WINDOW = 10;

     
    function getClaimAmountForBlock(uint block_number) constant returns (uint) {
         
        var call = FutureBlockCall(this);

        uint cutoff = call.targetBlock() - BEFORE_CALL_FREEZE_WINDOW;

         
        if (block_number > cutoff) return call.basePayment();

        cutoff -= MAXIMUM_CLAIM_WINDOW;

         
        if (block_number > cutoff) return call.basePayment();

        cutoff -= CLAIM_GROWTH_WINDOW;

        if (block_number > cutoff) {
            uint x = block_number - cutoff;

            return call.basePayment() * x / CLAIM_GROWTH_WINDOW;
        }

        return 0;
    }

    function lastClaimBlock() constant returns (uint) {
        var call = FutureBlockCall(this);
        return call.targetBlock() - BEFORE_CALL_FREEZE_WINDOW;
    }

    function maxClaimBlock() constant returns (uint) {
        return lastClaimBlock() - MAXIMUM_CLAIM_WINDOW;
    }

    function firstClaimBlock() constant returns (uint) {
        return maxClaimBlock() - CLAIM_GROWTH_WINDOW;
    }

    function claim(Call storage self, address executor, uint deposit_amount, uint basePayment) public returns (bool) {
         
         
        if (deposit_amount < 2 * basePayment) return false;

        self.claimAmount = getClaimAmountForBlock(block.number);
        self.claimer = executor;
        self.claimerDeposit = deposit_amount;

         
        Claimed(executor, self.claimAmount);
    }

    function checkExecutionAuthorization(Call storage self, address executor, uint block_number) returns (bool) {
         
        var call = FutureBlockCall(this);

        uint targetBlock = call.targetBlock();

         
        if (block_number < targetBlock || block_number > targetBlock + call.gracePeriod()) throw;

         
         
        if (block_number - targetBlock < CALL_WINDOW_SIZE) {
        return (self.claimer == 0x0 || self.claimer == executor);
        }

         
        return true;
    }

    function isCancellable(Call storage self, address caller) returns (bool) {
        var _state = state(self);
        var call = FutureBlockCall(this);

        if (_state == State.Pending && caller == call.schedulerAddress()) {
            return true;
        }

        if (_state == State.Missed) return true;

        return false;
    }

    function beforeExecuteForFutureBlockCall(Call storage self, address executor, uint startGas) returns (bool) {
        bytes32 reason;

        var call = FutureBlockCall(this);

        if (startGas < self.requiredGas) {
             
            reason = "NOT_ENOUGH_GAS";
        }
        else if (self.wasCalled) {
             
            reason = "ALREADY_CALLED";
        }
        else if (block.number < call.targetBlock() || block.number > call.targetBlock() + call.gracePeriod()) {
             
            reason = "NOT_IN_CALL_WINDOW";
        }
        else if (!checkExecutionAuthorization(self, executor, block.number)) {
             
             
            reason = "NOT_AUTHORIZED";
        }
        else if (self.requiredStackDepth > 0 && executor != tx.origin && !checkDepth(self.requiredStackDepth)) {
            reason = "STACK_TOO_DEEP";
        }

        if (reason != 0x0) {
            CallAborted(executor, reason);
            return false;
        }

        return true;
    }
}


contract FutureCall {
     
    address constant creator = 0xd3cda913deb6f67967b99d67acdfa1712c293601;

    address public schedulerAddress;

    uint public basePayment;
    uint public baseDonation;

    CallLib.Call call;

    address public origin;

    function FutureCall(address _schedulerAddress,
                        uint _requiredGas,
                        uint16 _requiredStackDepth,
                        address _contractAddress,
                        bytes4 _abiSignature,
                        bytes _callData,
                        uint _callValue,
                        uint _basePayment,
                        uint _baseDonation)
    {
        origin = msg.sender;
        schedulerAddress = _schedulerAddress;

        basePayment = _basePayment;
        baseDonation = _baseDonation;

        call.requiredGas = _requiredGas;
        call.requiredStackDepth = _requiredStackDepth;
        call.anchorGasPrice = tx.gasprice;
        call.contractAddress = _contractAddress;
        call.abiSignature = _abiSignature;
        call.callData = _callData;
        call.callValue = _callValue;
    }

    enum State {
        Pending,
        Unclaimed,
        Claimed,
        Frozen,
        Callable,
        Executed,
        Cancelled,
        Missed
    }

    modifier in_state(State _state) { if (state() == _state) _ }

    function state() constant returns (State) {
        return State(CallLib.state(call));
    }

     
    function beforeExecute(address executor, uint startGas) public returns (bool);
    function afterExecute(address executor) internal;
    function getOverhead() constant returns (uint);
    function getExtraGas() constant returns (uint);

     
    function contractAddress() constant returns (address) {
        return call.contractAddress;
    }

    function abiSignature() constant returns (bytes4) {
        return call.abiSignature;
    }

    function callData() constant returns (bytes) {
        return call.callData;
    }

    function callValue() constant returns (uint) {
        return call.callValue;
    }

    function anchorGasPrice() constant returns (uint) {
        return call.anchorGasPrice;
    }

    function requiredGas() constant returns (uint) {
        return call.requiredGas;
    }

    function requiredStackDepth() constant returns (uint16) {
        return call.requiredStackDepth;
    }

    function claimer() constant returns (address) {
        return call.claimer;
    }

    function claimAmount() constant returns (uint) {
        return call.claimAmount;
    }

    function claimerDeposit() constant returns (uint) {
        return call.claimerDeposit;
    }

    function wasSuccessful() constant returns (bool) {
        return call.wasSuccessful;
    }

    function wasCalled() constant returns (bool) {
        return call.wasCalled;
    }

    function isCancelled() constant returns (bool) {
        return call.isCancelled;
    }

     
    function getClaimAmountForBlock() constant returns (uint) {
        return CallLib.getClaimAmountForBlock(block.number);
    }

    function getClaimAmountForBlock(uint block_number) constant returns (uint) {
        return CallLib.getClaimAmountForBlock(block_number);
    }

     
    function () returns (bool) {
         
         
        if (msg.sender != schedulerAddress) return false;
         
        if (call.callData.length > 0) return false;

        var _state = state();
        if (_state != State.Pending && _state != State.Unclaimed && _state != State.Claimed) return false;

        call.callData = msg.data;
        return true;
    }

    function registerData() public returns (bool) {
         
        if (msg.sender != schedulerAddress) return false;
         
        if (call.callData.length > 0) return false;

        var _state = state();
        if (_state != State.Pending && _state != State.Unclaimed && _state != State.Claimed) return false;

        CallLib.extractCallData(call, msg.data);
    }

    function firstClaimBlock() constant returns (uint) {
        return CallLib.firstClaimBlock();
    }

    function maxClaimBlock() constant returns (uint) {
        return CallLib.maxClaimBlock();
    }

    function lastClaimBlock() constant returns (uint) {
        return CallLib.lastClaimBlock();
    }

    function claim() public in_state(State.Unclaimed) returns (bool) {
        bool success = CallLib.claim(call, msg.sender, msg.value, basePayment);
        if (!success) {
            if (!AccountingLib.sendRobust(msg.sender, msg.value)) throw;
        }
        return success;
    }

    function checkExecutionAuthorization(address executor, uint block_number) constant returns (bool) {
        return CallLib.checkExecutionAuthorization(call, executor, block_number);
    }

    function sendSafe(address to_address, uint value) internal {
        CallLib.sendSafe(to_address, value);
    }

    function execute() public in_state(State.Callable) {
        uint start_gas = msg.gas;

         
        if (!beforeExecute(msg.sender, start_gas)) return;

         
        CallLib.execute(call, start_gas, msg.sender, getOverhead(), getExtraGas());

         
         
        afterExecute(msg.sender);
    }
}


contract FutureBlockCall is FutureCall {
    uint public targetBlock;
    uint8 public gracePeriod;

    uint constant CALL_API_VERSION = 2;

    function callAPIVersion() constant returns (uint) {
        return CALL_API_VERSION;
    }

    function FutureBlockCall(address _schedulerAddress,
                             uint _targetBlock,
                             uint8 _gracePeriod,
                             address _contractAddress,
                             bytes4 _abiSignature,
                             bytes _callData,
                             uint _callValue,
                             uint _requiredGas,
                             uint16 _requiredStackDepth,
                             uint _basePayment,
                             uint _baseDonation)
        FutureCall(_schedulerAddress, _requiredGas, _requiredStackDepth, _contractAddress, _abiSignature, _callData, _callValue, _basePayment, _baseDonation)
    {
         
        schedulerAddress = _schedulerAddress;

        targetBlock = _targetBlock;
        gracePeriod = _gracePeriod;
    }

    uint constant GAS_PER_DEPTH = 700;

    function __dig(uint n) constant returns (bool) {
        if (n == 0) return true;
        if (!address(this).callcode(bytes4(sha3("__dig(uint256)")), n - 1)) throw;
    }


    function beforeExecute(address executor, uint startGas) public returns (bool) {
        return CallLib.beforeExecuteForFutureBlockCall(call, executor, startGas);
    }

    function afterExecute(address executor) internal {
         
        CallLib.sendSafe(schedulerAddress, address(this).balance);
    }

    uint constant GAS_OVERHEAD = 100000;

    function getOverhead() constant returns (uint) {
            return GAS_OVERHEAD;
    }

    uint constant EXTRA_GAS = 77000;

    function getExtraGas() constant returns (uint) {
            return EXTRA_GAS;
    }

    uint constant CLAIM_GROWTH_WINDOW = 240;
    uint constant MAXIMUM_CLAIM_WINDOW = 15;
    uint constant BEFORE_CALL_FREEZE_WINDOW = 10;

    function isCancellable() constant public returns (bool) {
        return CallLib.isCancellable(call, msg.sender);
    }

    function cancel() public {
        if (CallLib.isCancellable(call, msg.sender)) {
            CallLib.cancel(call, msg.sender);
        }
    }
}


library SchedulerLib {
     
     
    function version() constant returns (uint16, uint16, uint16) {
        return (0, 7, 0);
    }

     
    uint constant MIN_BLOCKS_IN_FUTURE = 10;

     
    uint8 constant DEFAULT_GRACE_PERIOD = 255;

     
     
     
     
     
    uint constant MINIMUM_CALL_GAS = 200000;

     
    uint16 constant MINIMUM_STACK_CHECK = 10;

     
     
    uint16 constant MAXIMUM_STACK_CHECK = 1000;

    event CallScheduled(address call_address);

    event CallRejected(address indexed schedulerAddress, bytes32 reason);

    uint constant CALL_WINDOW_SIZE = 16;

    function getMinimumStackCheck() constant returns (uint16) {
        return MINIMUM_STACK_CHECK;
    }

    function getMaximumStackCheck() constant returns (uint16) {
        return MAXIMUM_STACK_CHECK;
    }

    function getCallWindowSize() constant returns (uint) {
        return CALL_WINDOW_SIZE;
    }

    function getMinimumGracePeriod() constant returns (uint) {
        return 2 * CALL_WINDOW_SIZE;
    }

    function getDefaultGracePeriod() constant returns (uint8) {
        return DEFAULT_GRACE_PERIOD;
    }

    function getMinimumCallGas() constant returns (uint) {
        return MINIMUM_CALL_GAS;
    }

    function getMaximumCallGas() constant returns (uint) {
        return block.gaslimit - getMinimumCallGas();
    }

    function getMinimumCallCost(uint basePayment, uint baseDonation) constant returns (uint) {
        return 2 * (baseDonation + basePayment) + MINIMUM_CALL_GAS * tx.gasprice;
    }

    function getFirstSchedulableBlock() constant returns (uint) {
        return block.number + MIN_BLOCKS_IN_FUTURE;
    }

    function getMinimumEndowment(uint basePayment,
                                 uint baseDonation,
                                 uint callValue,
                                 uint requiredGas) constant returns (uint endowment) {
            endowment += tx.gasprice * requiredGas;
            endowment += 2 * (basePayment + baseDonation);
            endowment += callValue;

            return endowment;
    }

    struct CallConfig {
        address schedulerAddress;
        address contractAddress;
        bytes4 abiSignature;
        bytes callData;
        uint callValue;
        uint8 gracePeriod;
        uint16 requiredStackDepth;
        uint targetBlock;
        uint requiredGas;
        uint basePayment;
        uint baseDonation;
        uint endowment;
    }

    function scheduleCall(GroveLib.Index storage callIndex,
                          address schedulerAddress,
                          address contractAddress,
                          bytes4 abiSignature,
                          bytes callData,
                          uint8 gracePeriod,
                          uint16 requiredStackDepth,
                          uint callValue,
                          uint targetBlock,
                          uint requiredGas,
                          uint basePayment,
                          uint baseDonation,
                          uint endowment) public returns (address) {
        CallConfig memory callConfig = CallConfig({
            schedulerAddress: schedulerAddress,
            contractAddress: contractAddress,
            abiSignature: abiSignature,
            callData: callData,
            gracePeriod: gracePeriod,
            requiredStackDepth: requiredStackDepth,
            callValue: callValue,
            targetBlock: targetBlock,
            requiredGas: requiredGas,
            basePayment: basePayment,
            baseDonation: baseDonation,
            endowment: endowment,
        });
        return _scheduleCall(callIndex, callConfig);
    }

    function scheduleCall(GroveLib.Index storage callIndex,
                          address[2] addresses,
                          bytes4 abiSignature,
                          bytes callData,
                          uint8 gracePeriod,
                          uint16 requiredStackDepth,
                          uint[6] uints) public returns (address) {
        CallConfig memory callConfig = CallConfig({
            schedulerAddress: addresses[0],
            contractAddress: addresses[1],
            abiSignature: abiSignature,
            callData: callData,
            gracePeriod: gracePeriod,
            requiredStackDepth: requiredStackDepth,
            callValue: uints[0],
            targetBlock: uints[1],
            requiredGas: uints[2],
            basePayment: uints[3],
            baseDonation: uints[4],
            endowment: uints[5],
        });
        return _scheduleCall(callIndex, callConfig);

    }

    function _scheduleCall(GroveLib.Index storage callIndex, CallConfig memory callConfig) internal returns (address) {
         
        bytes32 reason;

        if (callConfig.targetBlock < block.number + MIN_BLOCKS_IN_FUTURE) {
             
             
            reason = "TOO_SOON";
        }
        else if (getMinimumStackCheck() > callConfig.requiredStackDepth || callConfig.requiredStackDepth > getMaximumStackCheck()) {
             
             
            reason = "STACK_CHECK_OUT_OF_RANGE";
        }
        else if (callConfig.gracePeriod < getMinimumGracePeriod()) {
            reason = "GRACE_TOO_SHORT";
        }
        else if (callConfig.requiredGas < getMinimumCallGas() || callConfig.requiredGas > getMaximumCallGas()) {
            reason = "REQUIRED_GAS_OUT_OF_RANGE";
        }
        else if (callConfig.endowment < getMinimumEndowment(callConfig.basePayment, callConfig.baseDonation, callConfig.callValue, callConfig.requiredGas)) {
            reason = "INSUFFICIENT_FUNDS";
        }

        if (reason != 0x0) {
            CallRejected(callConfig.schedulerAddress, reason);
            AccountingLib.sendRobust(callConfig.schedulerAddress, callConfig.endowment);
            return;
        }

        var call = (new FutureBlockCall).value(callConfig.endowment)(
                callConfig.schedulerAddress,
                callConfig.targetBlock,
                callConfig.gracePeriod,
                callConfig.contractAddress,
                callConfig.abiSignature,
                callConfig.callData,
                callConfig.callValue,
                callConfig.requiredGas,
                callConfig.requiredStackDepth,
                callConfig.basePayment,
                callConfig.baseDonation
        );

         
        GroveLib.insert(callIndex, bytes32(address(call)), int(call.targetBlock()));

        CallScheduled(address(call));

        return address(call);
    }
}


contract Scheduler {
     

     
    uint constant INITIAL_DEFAUlT_PAYMENT = 5 finney;

    uint public defaultPayment;

    function Scheduler() {
        defaultPayment = INITIAL_DEFAUlT_PAYMENT;
    }

     
    GroveLib.Index callIndex;

    uint constant CALL_API_VERSION = 7;

    function callAPIVersion() constant returns (uint) {
        return CALL_API_VERSION;
    }

     
    function getMinimumGracePeriod() constant returns (uint) {
        return SchedulerLib.getMinimumGracePeriod();
    }

     
    modifier only_known_call { if (isKnownCall(msg.sender)) _ }

    function updateDefaultPayment() public only_known_call {
        var call = FutureBlockCall(msg.sender);
        var basePayment = call.basePayment();

        if (call.wasCalled() && call.claimer() != 0x0 && basePayment > 0 && defaultPayment > 1) {
            var index = call.claimAmount() * 100 / basePayment;

            if (index > 66 && defaultPayment <= basePayment) {
                 
                defaultPayment = defaultPayment * 10001 / 10000;
            }
            else if (index < 33 && defaultPayment >= basePayment) {
                 
                defaultPayment = defaultPayment * 9999 / 10000;
            }
        }
    }

    function getDefaultDonation() constant returns (uint) {
        return defaultPayment / 100;
    }

    function getMinimumCallGas() constant returns (uint) {
        return SchedulerLib.getMinimumCallGas();
    }

    function getMaximumCallGas() constant returns (uint) {
        return SchedulerLib.getMaximumCallGas();
    }

    function getMinimumEndowment() constant returns (uint) {
        return SchedulerLib.getMinimumEndowment(defaultPayment, getDefaultDonation(), 0, getDefaultRequiredGas());
    }

    function getMinimumEndowment(uint basePayment) constant returns (uint) {
        return SchedulerLib.getMinimumEndowment(basePayment, getDefaultDonation(), 0, getDefaultRequiredGas());
    }

    function getMinimumEndowment(uint basePayment, uint baseDonation) constant returns (uint) {
        return SchedulerLib.getMinimumEndowment(basePayment, baseDonation, 0, getDefaultRequiredGas());
    }

    function getMinimumEndowment(uint basePayment, uint baseDonation, uint callValue) constant returns (uint) {
        return SchedulerLib.getMinimumEndowment(basePayment, baseDonation, callValue, getDefaultRequiredGas());
    }

    function getMinimumEndowment(uint basePayment, uint baseDonation, uint callValue, uint requiredGas) constant returns (uint) {
        return SchedulerLib.getMinimumEndowment(basePayment, baseDonation, callValue, requiredGas);
    }

    function isKnownCall(address callAddress) constant returns (bool) {
        return GroveLib.exists(callIndex, bytes32(callAddress));
    }

    function getFirstSchedulableBlock() constant returns (uint) {
        return SchedulerLib.getFirstSchedulableBlock();
    }

    function getMinimumStackCheck() constant returns (uint16) {
        return SchedulerLib.getMinimumStackCheck();
    }

    function getMaximumStackCheck() constant returns (uint16) {
        return SchedulerLib.getMaximumStackCheck();
    }

    function getDefaultStackCheck() constant returns (uint16) {
        return getMinimumStackCheck();
    }

    function getDefaultRequiredGas() constant returns (uint) {
        return SchedulerLib.getMinimumCallGas();
    }

    function getDefaultGracePeriod() constant returns (uint8) {
        return SchedulerLib.getDefaultGracePeriod();
    }

    bytes constant EMPTY_CALL_DATA = "";
    uint constant DEFAULT_CALL_VALUE = 0;
    bytes4 constant DEFAULT_FN_SIGNATURE = 0x0000;

    function scheduleCall() public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, msg.sender,
            DEFAULT_FN_SIGNATURE, EMPTY_CALL_DATA, getDefaultGracePeriod(), getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, getFirstSchedulableBlock(), getDefaultRequiredGas(), defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(uint targetBlock) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, msg.sender,
            DEFAULT_FN_SIGNATURE, EMPTY_CALL_DATA, getDefaultGracePeriod(), getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, targetBlock, getDefaultRequiredGas(), defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(bytes callData) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, msg.sender,
            DEFAULT_FN_SIGNATURE, callData, getDefaultGracePeriod(), getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, getFirstSchedulableBlock(), getDefaultRequiredGas(), defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(bytes4 abiSignature,
                          bytes callData) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, msg.sender,
            abiSignature, callData, getDefaultGracePeriod(), getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, getFirstSchedulableBlock(), getDefaultRequiredGas(), defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(bytes4 abiSignature) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, msg.sender,
            abiSignature, EMPTY_CALL_DATA, getDefaultGracePeriod(), getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, getFirstSchedulableBlock(), getDefaultRequiredGas(), defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(address contractAddress) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            DEFAULT_FN_SIGNATURE, EMPTY_CALL_DATA, getDefaultGracePeriod(), getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, getFirstSchedulableBlock(), getDefaultRequiredGas(), defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(address contractAddress,
                          bytes4 abiSignature) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            abiSignature, EMPTY_CALL_DATA, getDefaultGracePeriod(), getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, getFirstSchedulableBlock(), getDefaultRequiredGas(), defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(address contractAddress,
                          uint callValue,
                          bytes4 abiSignature) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            abiSignature, EMPTY_CALL_DATA, getDefaultGracePeriod(), getDefaultStackCheck(),
            callValue, getFirstSchedulableBlock(), getDefaultRequiredGas(), defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(address contractAddress,
                          bytes4 abiSignature,
                          bytes callData) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            abiSignature, callData, getDefaultGracePeriod(), getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, getFirstSchedulableBlock(), getDefaultRequiredGas(), defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(address contractAddress,
                          bytes4 abiSignature,
                          uint callValue,
                          bytes callData) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            abiSignature, callData, getDefaultGracePeriod(), getDefaultStackCheck(),
            callValue, getFirstSchedulableBlock(), getDefaultRequiredGas(), defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(uint callValue,
                          address contractAddress) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            DEFAULT_FN_SIGNATURE, EMPTY_CALL_DATA, getDefaultGracePeriod(), getDefaultStackCheck(),
            callValue, getFirstSchedulableBlock(), getDefaultRequiredGas(), defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(address contractAddress,
                          uint targetBlock) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            DEFAULT_FN_SIGNATURE, EMPTY_CALL_DATA, getDefaultGracePeriod(), getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, targetBlock, getDefaultRequiredGas(), defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(address contractAddress,
                          uint targetBlock,
                          uint callValue) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            DEFAULT_FN_SIGNATURE, EMPTY_CALL_DATA, getDefaultGracePeriod(), getDefaultStackCheck(),
            callValue, targetBlock, getDefaultRequiredGas(), defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(bytes4 abiSignature,
                          uint targetBlock) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, msg.sender,
            abiSignature, EMPTY_CALL_DATA, getDefaultGracePeriod(), getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, targetBlock, getDefaultRequiredGas(), defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(address contractAddress,
                          bytes4 abiSignature,
                          uint targetBlock) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            abiSignature, EMPTY_CALL_DATA, getDefaultGracePeriod(), getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, targetBlock, getDefaultRequiredGas(), defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(bytes4 abiSignature,
                          bytes callData,
                          uint targetBlock) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, msg.sender,
            abiSignature, callData, getDefaultGracePeriod(), getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, targetBlock, getDefaultRequiredGas(), defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(address contractAddress,
                          bytes4 abiSignature,
                          bytes callData,
                          uint targetBlock) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            abiSignature, callData, getDefaultGracePeriod(), getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, targetBlock, getDefaultRequiredGas(), defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(address contractAddress,
                          bytes4 abiSignature,
                          uint callValue,
                          bytes callData,
                          uint targetBlock) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            abiSignature, callData, getDefaultGracePeriod(), getDefaultStackCheck(),
            callValue, targetBlock, getDefaultRequiredGas(), defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(bytes4 abiSignature,
                          uint targetBlock,
                          uint requiredGas) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, msg.sender,
            abiSignature, EMPTY_CALL_DATA, getDefaultGracePeriod(), getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, targetBlock, requiredGas, defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(address contractAddress,
                          bytes4 abiSignature,
                          uint targetBlock,
                          uint requiredGas) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            abiSignature, EMPTY_CALL_DATA, getDefaultGracePeriod(), getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, targetBlock, requiredGas, defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(bytes4 abiSignature,
                          bytes callData,
                          uint targetBlock,
                          uint requiredGas) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, msg.sender,
            abiSignature, callData, getDefaultGracePeriod(), getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, targetBlock, requiredGas, defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(address contractAddress,
                          bytes4 abiSignature,
                          bytes callData,
                          uint targetBlock,
                          uint requiredGas) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            abiSignature, callData, getDefaultGracePeriod(), getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, targetBlock, requiredGas, defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(bytes4 abiSignature,
                          uint targetBlock,
                          uint requiredGas,
                          uint8 gracePeriod) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, msg.sender,
            abiSignature, EMPTY_CALL_DATA, gracePeriod, getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, targetBlock, requiredGas, defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(address contractAddress,
                          uint callValue,
                          bytes4 abiSignature,
                          uint targetBlock,
                          uint requiredGas,
                          uint8 gracePeriod) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            abiSignature, EMPTY_CALL_DATA, gracePeriod, getDefaultStackCheck(),
            callValue, targetBlock, requiredGas, defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(address contractAddress,
                          bytes4 abiSignature,
                          uint targetBlock,
                          uint requiredGas,
                          uint8 gracePeriod) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            abiSignature, EMPTY_CALL_DATA, gracePeriod, getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, targetBlock, requiredGas, defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(address contractAddress,
                          bytes4 abiSignature,
                          bytes callData,
                          uint targetBlock,
                          uint requiredGas,
                          uint8 gracePeriod) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            abiSignature, callData, gracePeriod, getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, targetBlock, requiredGas, defaultPayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(bytes4 abiSignature,
                          uint targetBlock,
                          uint requiredGas,
                          uint8 gracePeriod,
                          uint basePayment) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, msg.sender,
            abiSignature, EMPTY_CALL_DATA, gracePeriod, getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, targetBlock, requiredGas, basePayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(address contractAddress,
                          uint callValue,
                          bytes4 abiSignature,
                          uint targetBlock,
                          uint requiredGas,
                          uint8 gracePeriod,
                          uint basePayment) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            abiSignature, EMPTY_CALL_DATA, gracePeriod, getDefaultStackCheck(),
            callValue, targetBlock, requiredGas, basePayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(address contractAddress,
                          bytes4 abiSignature,
                          uint targetBlock,
                          uint requiredGas,
                          uint8 gracePeriod,
                          uint basePayment) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            abiSignature, EMPTY_CALL_DATA, gracePeriod, getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, targetBlock, requiredGas, basePayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(bytes4 abiSignature,
                          bytes callData,
                          uint targetBlock,
                          uint requiredGas,
                          uint8 gracePeriod,
                          uint basePayment) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, msg.sender,
            abiSignature, callData, gracePeriod, getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, targetBlock, requiredGas, basePayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(address contractAddress,
                          bytes4 abiSignature,
                          bytes callData,
                          uint8 gracePeriod,
                          uint[4] args) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            abiSignature, callData, gracePeriod, getDefaultStackCheck(),
             
            args[0], args[1], args[2], args[3], getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(address contractAddress,
                          bytes4 abiSignature,
                          bytes callData,
                          uint targetBlock,
                          uint requiredGas,
                          uint8 gracePeriod,
                          uint basePayment) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, contractAddress,
            abiSignature, callData, gracePeriod, getDefaultStackCheck(),
            DEFAULT_CALL_VALUE, targetBlock, requiredGas, basePayment, getDefaultDonation(), msg.value
        );
    }

    function scheduleCall(bytes4 abiSignature,
                          bytes callData,
                          uint16 requiredStackDepth,
                          uint8 gracePeriod,
                          uint callValue,
                          uint targetBlock,
                          uint requiredGas,
                          uint basePayment,
                          uint baseDonation) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            msg.sender, msg.sender,
            abiSignature, callData, gracePeriod, requiredStackDepth,
            callValue, targetBlock, requiredGas, basePayment, baseDonation, msg.value
        );
    }

    function scheduleCall(address contractAddress,
                          bytes4 abiSignature,
                          bytes callData,
                          uint16 requiredStackDepth,
                          uint8 gracePeriod,
                          uint[5] args) public returns (address) {
        return SchedulerLib.scheduleCall(
            callIndex,
            [msg.sender, contractAddress],
            abiSignature, callData, gracePeriod, requiredStackDepth,
             
            [args[0], args[1], args[2], args[3], args[4], msg.value]
        );
    }

     
    function getCallWindowSize() constant returns (uint) {
            return SchedulerLib.getCallWindowSize();
    }

    function getNextCall(uint blockNumber) constant returns (address) {
            return address(GroveLib.query(callIndex, ">=", int(blockNumber)));
    }

    function getNextCallSibling(address callAddress) constant returns (address) {
            return address(GroveLib.getNextNode(callIndex, bytes32(callAddress)));
    }
}