
-record(phone,
	{
		channel,
		side,
		queue
	}
).


-define(X_Front_Score, 5).
-define(X_Near_Score, 4).
-define(X_Around_Score, 3).
-define(X_FarEnemy_Score, 2).
-define(X_Forward_Score, 1).
-define(X_None_Score, 0).
