pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "/CasinoContractInterface.sol";

contract CasinoContract{

    uint constant MAX_PLAYERS_IN_SESSION = 5;
    uint constant PAY_ALL_FEES_FLAG = 65;

    mapping(address => string) nicknames;
    Session[] sessions;
    mapping(uint => SessionResult) sessionResults;



    modifier ifSessionNotOver(address playerAddress, uint128 bet){
        if(getCurrentSession().done){
            playerAddress.transfer(bet, false, uint16(PAY_ALL_FEES_FLAG));
        }
        require(getCurrentSession().done, 400, "Session is over. Try again in new session");
        _;
    }

    function getCurrentSession() public view returns (Session){
        if(sessions.length == 0) return Session(0, (), (), false, ());
        return sessions[sessions.length - 1];
    }

    function getLastSessions(uint sessionNum) public view returns(SessionResult[]) {
        uint sessionsArrayLength = sessions.length;
        if(sessionsArrayLength <= sessionNum) return sessionResults;
        else {
            SessionResult[] lastSessions = new SessionResult[](sessionNum);
            for(uint i = 0; i < sessionNum; i++){  
                lastSessions.push(sessionResults[sessionsArrayLength - i - 1]);
            }
            return lastSessions;
        }
    }

    receive() external{
        //tvm.accept() maybe
        address playerAddress = msg.sender;
        uint bet = msg.value;
        makeABet(bet, playerAddress);
    }

    function makeABet(uint bet, 
    address playerAddress) public 
    ifSessionNotOver(playerAddress, uint128(bet)) returns(Session){
        Session currentSession = getCurrentSession();
        bool playerAlreadyPresent = isInSession(playerAddress);
        if(!playerAlreadyPresent) currentSession.participants.push(playerAddress);
        currentSession.bets[playerAddress] += bet;
        if(currentSession.participants.length == MAX_PLAYERS_IN_SESSION) calculateSessionResults();
    }

    function isInSession(address playerAddress) public returns(bool){
        address[] currentSessionPlayers = getCurrentSession().participants;
        for(uint i = 0; i < currentSessionPlayers.length; i++){
            if(currentSessionPlayers[i] == playerAddress) return true;
        }
        return false;
    }

    function calculateSessionResults() private{
        Session currentSession = getCurrentSession();
        uint betsSum = 0;
        address[] participants = currentSession.participants;
        for(uint i = 0; i < participants.length; i++){
            currentSession.bets[participants[i]] += betsSum;
        }
        uint[MAX_PLAYERS_IN_SESSION] betsWeight;
        for(uint i = 0; i < MAX_PLAYERS_IN_SESSION; i++){
            betsWeight.push(betsSum - (betsSum / currentSession.bets[participants[i]]) + 1);
        }
        uint timestamp = now;
        uint winningTicket = timestamp % betsSum;
        uint currentSum = 0;
        for(uint i = 0; i < MAX_PLAYERS_IN_SESSION; i++){
            if(currentSum + betsWeight[i] <= winningTicket){
                 setWinner(participants[i], betsSum / 10, timestamp);
                 break;
            }
            currentSum += betsWeight[i];
        }
    }

    function getBetsArray(Session session) public returns(uint[]){
        uint[] bets;
        address[] sessionParticipants = session.participants;
        for(uint i = 0; i < sessionParticipants.length; i++){
            bets.push(session.bets[sessionParticipants[i]]);
        }
        return bets;
    }

    function setWinner(address winner, uint amount, uint timestamp) private{
        Session lastSession = getCurrentSession();
        SessionResult result = SessionResult(lastSession.id,
            lastSession.participants, getBetsArray(lastSession), winner, timestamp);
        sessionResults[lastSession.id] = result;
        winner.transfer(uint128(amount), false, uint16(PAY_ALL_FEES_FLAG));
        makeNewGame();
    }

    function makeNewGame() private{
        
    }



}