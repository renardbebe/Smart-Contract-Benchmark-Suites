 

pragma solidity 0.4.16;

contract FiveMedium {
	
	 
	address private owner;

	 
	uint256 public feeNewThread;
	uint256 public feeReplyThread;

	 
	 
	 

	 
	struct thread {
		string text;
		string imageUrl;

		uint256 indexLastReply;
		uint256 indexFirstReply;

		uint256 timestamp;
	}
	mapping (uint256 => thread) public threads;
	uint256 public indexThreads = 1;

	 
	struct reply {
		string text;
		string imageUrl;

		uint256 replyTo;
		uint256 nextReply;

		uint256 timestamp;
	}
	mapping (uint256 => reply) public replies;
	uint256 public indexReplies = 1;

	 
	uint256[20] public lastThreads;
	uint256 public indexLastThreads = 0;  

	 
	 
	 

	event newThreadEvent(uint256 threadId, string text, string imageUrl, uint256 timestamp);

	event newReplyEvent(uint256 replyId, uint256 replyTo, string text, string imageUrl, uint256 timestamp);

	 
	 
	 

	 
	function FiveMedium(uint256 _feeNewThread, uint256 _feeReplyThread) public {
		owner = msg.sender;
		feeNewThread = _feeNewThread;
		feeReplyThread = _feeReplyThread;
	}
	
	 
	function SetFees(uint256 _feeNewThread, uint256 _feeReplyThread) public {
		require(owner == msg.sender);
		feeNewThread = _feeNewThread;
		feeReplyThread = _feeReplyThread;
	}

	 
	function withdraw(uint256 amount) public {
		owner.transfer(amount);
	}

	 
	 
	 

	 
	function createThread(string _text, string _imageUrl) payable public {
		 
		require(msg.value >= feeNewThread); 
		 
		threads[indexThreads] = thread(_text, _imageUrl, 0, 0, now);
		 
		lastThreads[indexLastThreads] = indexThreads;
		indexLastThreads = addmod(indexLastThreads, 1, 20);  
		 
		newThreadEvent(indexThreads, _text, _imageUrl, now);
		 
		indexThreads += 1;
	}

	 
	function replyThread(uint256 _replyTo, string _text, string _imageUrl)  payable public {
		 
		require(msg.value >= feeReplyThread);
		 
		require(_replyTo < indexThreads && _replyTo > 0);
		 
		replies[indexReplies] = reply(_text, _imageUrl, _replyTo, 0, now);
		 
		if(threads[_replyTo].indexFirstReply == 0){ 
			threads[_replyTo].indexFirstReply = indexReplies;
			threads[_replyTo].indexLastReply = indexReplies;
		}
		else {  
			replies[threads[_replyTo].indexLastReply].nextReply = indexReplies;
			threads[_replyTo].indexLastReply = indexReplies;
		}
		 
		for (uint8 i = 0; i < 20; i++) { 
			if(lastThreads[i] == _replyTo) {
				break;  
			}
			if(i == 19) {
				lastThreads[indexLastThreads] = _replyTo;
				indexLastThreads = addmod(indexLastThreads, 1, 20);
			}
		} 
		 
		newReplyEvent(indexReplies, _replyTo, _text, _imageUrl, now);
		 
		indexReplies += 1;
	}
}