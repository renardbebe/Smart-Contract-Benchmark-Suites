 

pragma solidity ^0.5.10;


contract Ownable {
    address public owner;

    event TransferOwnership(address _from, address _to);

    constructor() public {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        emit TransferOwnership(owner, _owner);
        owner = _owner;
    }
}

 

pragma solidity ^0.5.10;

 


library AddressMinHeap {
    using AddressMinHeap for AddressMinHeap.Heap;

    struct Heap {
        uint256[] entries;
        mapping(address => uint256) index;
    }

    function initialize(Heap storage _heap) internal {
        require(_heap.entries.length == 0, "already initialized");
        _heap.entries.push(0);
    }

    function encode(address _addr, uint256 _value) internal pure returns (uint256 _entry) {
         
        assembly {
            _entry := not(or(and(0xffffffffffffffffffffffffffffffffffffffff, _addr), shl(160, _value)))
        }
    }

    function decode(uint256 _entry) internal pure returns (address _addr, uint256 _value) {
         
        assembly {
            let entry := not(_entry)
            _addr := and(entry, 0xffffffffffffffffffffffffffffffffffffffff)
            _value := shr(160, entry)
        }
    }

    function decodeAddress(uint256 _entry) internal pure returns (address _addr) {
         
        assembly {
            _addr := and(not(_entry), 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }

    function top(Heap storage _heap) internal view returns(address, uint256) {
        if (_heap.entries.length < 2) {
            return (address(0), 0);
        }

        return decode(_heap.entries[1]);
    }

    function has(Heap storage _heap, address _addr) internal view returns (bool) {
        return _heap.index[_addr] != 0;
    }

    function size(Heap storage _heap) internal view returns (uint256) {
        return _heap.entries.length - 1;
    }

    function entry(Heap storage _heap, uint256 _i) internal view returns (address, uint256) {
        return decode(_heap.entries[_i + 1]);
    }

     
    function popTop(Heap storage _heap) internal returns(address _addr, uint256 _value) {
         
        uint256 heapLength = _heap.entries.length;
        require(heapLength > 1, "The heap does not exists");

         
        (_addr, _value) = decode(_heap.entries[1]);
        _heap.index[_addr] = 0;

        if (heapLength == 2) {
            _heap.entries.length = 1;
        } else {
             
            uint256 val = _heap.entries[heapLength - 1];
            _heap.entries[1] = val;

             
            _heap.entries.length = heapLength - 1;

             
            uint256 ind = 1;

             
            ind = _heap.bubbleDown(ind, val);

             
            _heap.index[decodeAddress(val)] = ind;
        }
    }

     
    function insert(Heap storage _heap, address _addr, uint256 _value) internal {
        require(_heap.index[_addr] == 0, "The entry already exists");

         
        uint256 encoded = encode(_addr, _value);
        _heap.entries.push(encoded);

         
        uint256 currentIndex = _heap.entries.length - 1;

         
        currentIndex = _heap.bubbleUp(currentIndex, encoded);

         
        _heap.index[_addr] = currentIndex;
    }

    function update(Heap storage _heap, address _addr, uint256 _value) internal {
        uint256 ind = _heap.index[_addr];
        require(ind != 0, "The entry does not exists");

        uint256 can = encode(_addr, _value);
        uint256 val = _heap.entries[ind];
        uint256 newInd;

        if (can < val) {
             
            newInd = _heap.bubbleDown(ind, can);
        } else if (can > val) {
             
            newInd = _heap.bubbleUp(ind, can);
        } else {
             
            return;
        }

         
        _heap.entries[newInd] = can;

         
        if (newInd != ind) {
            _heap.index[_addr] = newInd;
        }
    }

    function bubbleUp(Heap storage _heap, uint256 _ind, uint256 _val) internal returns (uint256 ind) {
         
        ind = _ind;
        if (ind != 1) {
            uint256 parent = _heap.entries[ind / 2];
            while (parent < _val) {
                 
                (_heap.entries[ind / 2], _heap.entries[ind]) = (_val, parent);

                 
                _heap.index[decodeAddress(parent)] = ind;

                 
                ind = ind / 2;
                if (ind == 1) {
                    break;
                }

                 
                parent = _heap.entries[ind / 2];
            }
        }
    }

    function bubbleDown(Heap storage _heap, uint256 _ind, uint256 _val) internal returns (uint256 ind) {
         
        ind = _ind;

        uint256 lenght = _heap.entries.length;
        uint256 target = lenght - 1;

        while (ind * 2 < lenght) {
             
            uint256 j = ind * 2;

             
            uint256 leftChild = _heap.entries[j];

             
            uint256 childValue;

            if (target > j) {
                 

                 
                uint256 rightChild = _heap.entries[j + 1];

                 
                 
                 
                if (leftChild < rightChild) {
                    childValue = rightChild;
                    j = j + 1;
                } else {
                     
                    childValue = leftChild;
                }
            } else {
                 
                childValue = leftChild;
            }

             
            if (_val > childValue) {
                break;
            }

             
            (_heap.entries[ind], _heap.entries[j]) = (childValue, _val);

             
            _heap.index[decodeAddress(childValue)] = ind;

             
            ind = j;
        }
    }
}

 

pragma solidity ^0.5.10;



contract Heap is Ownable {
    using AddressMinHeap for AddressMinHeap.Heap;

     
    AddressMinHeap.Heap private heap;

     
    event JoinHeap(address indexed _address, uint256 _balance, uint256 _prevSize);
    event LeaveHeap(address indexed _address, uint256 _balance, uint256 _prevSize);

    uint256 public constant TOP_SIZE = 112;

    constructor() public {
        heap.initialize();
    }

    function topSize() external pure returns (uint256) {
        return TOP_SIZE;
    }

    function addressAt(uint256 _i) external view returns (address addr) {
        (addr, ) = heap.entry(_i);
    }

    function indexOf(address _addr) external view returns (uint256) {
        return heap.index[_addr];
    }

    function entry(uint256 _i) external view returns (address, uint256) {
        return heap.entry(_i);
    }

    function top() external view returns (address, uint256) {
        return heap.top();
    }

    function size() external view returns (uint256) {
        return heap.size();
    }

    function update(address _addr, uint256 _new) external onlyOwner {
        uint256 _size = heap.size();

         
         
        if (_size == 0) {
            emit JoinHeap(_addr, _new, 0);
            heap.insert(_addr, _new);
            return;
        }

         
        (, uint256 lastBal) = heap.top();

         
        if (heap.has(_addr)) {
             
            heap.update(_addr, _new);
             
             
             
            if (_new == 0) {
                heap.popTop();
                emit LeaveHeap(_addr, 0, _size);
            }
        } else {
             
            if (_new != 0 && (_size < TOP_SIZE || lastBal < _new)) {
                 
                if (_size >= TOP_SIZE) {
                    (address _poped, uint256 _balance) = heap.popTop();
                    emit LeaveHeap(_poped, _balance, _size);
                }

                 
                heap.insert(_addr, _new);
                emit JoinHeap(_addr, _new, _size);
            }
        }
    }
}