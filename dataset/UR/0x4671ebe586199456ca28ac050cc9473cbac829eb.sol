 

contract Mortal {
        address public owner;
        function mortal() { owner = msg.sender; }
        function kill() { if (msg.sender == owner) suicide(owner); }
}

contract Thing is Mortal {
        enum Mood { Agree, Disagree, Funny, Sad, Angry, Nothing }
         
        string public url;
         
        string public data;
         
        string public mimetype;
         
        Mood public mood;
        Thing[] public reactions;

        function thing( string _url
                          , string _data
                          , Mood _mood
                          , string _mimetype) {
                url = _url;
                data = _data;
                mimetype = _mimetype;
                mood = _mood;
        }

        function react(Thing reaction) {
                if (msg.sender != reaction.owner()) throw;

                reactions.push(reaction);
        }

        function withdraw() {
                if (msg.sender != owner) throw;

                owner.send(this.balance);
        }
}