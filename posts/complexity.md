# When Is Complexity OK?

We all known complexity is bad. It slows down development, makes bugs more likely, increases the maintenance burden and makes it harder to onboard new developers. So why do we still have complex software everywhere? Legacy code, misaligned incentives, unclear goals, bad development practices or sheer incompetence can be causes. But even well run projects often get very complex because it is required to achieve the desired outcome ("essential complexity"). Distinguishing between essential and accidental complexity is hard and even if I could identify and remove all accidental complexity, one question would remain: Is the complexity level of this project healthy, or do I have to fundamentally change the overall approach (or declare the project a failure)?

<!--Is the essential complexity so high that the project is not viable within my development budget?-->
<!--When planning the next development steps I often wonder "Is the complexity level of this project healthy, or do I have to fundamentally change the approach (or declare the project a failure)?".-->

If I manage to keep the project very simple the answer is obvious, so let's ignore that case. Just looking at the complexity level is not sufficient, since there are many projects of significant complexity which are very health and have a bright future (e.g. Linux, SQLite, PostgreSQL). But these projects are mature enough to carry the weight of their complexity. But projects don't start out incredibly mature, so I need to know if they are on the trajectory to get into the realm of complex but healthy and mature, or whether they are set up for failure. Looking back, the best way to find out was to ask myself

"Is the project getting more mature faster than it is getting more complex?"

```
Complexity                    Complexity                
^                             ^                /
|                             |               /
|            ____             |             _/    
|        ___/                 |            /
|     __/                     |          _/
|   _/                        |         /
|  /                          |       _/
| /                           |    __/
|/                            |___/
+--------------> Maturity     +--------------> Maturity
  healthy project               unhealthy project
```

When I'm trying to get an early version mostly stable and bug-free, but each time I fix a problem, I have to add new concepts to handle those cases, that is an indication that I can't improve the maturity faster than the complexity. After all, when even fixing bugs does not improve the maturity/complexity ratio, then adding new features will be even worse. Continuing to work in the same won't be sustainable and I should look for a different approach of declare the project a failure. On the other hand, if I am able to fix bugs and fine-tune the program behavior without increasing the code size or making it harder to read, then I'm right on my way into the healthy "more mature than complex".

So now that you know my complexity assessment heuristic, let me point out some details:
* I used the term "project", but the same approach works on different levels. E.g. a complexity and maturity of a single feature can be compared in the same way.
* When the result is unclear, assume that you are in the unhealthy case. We tend to overestimate maturity until we had enough time to observe many edge cases.
* There certainly are other approaches which are better in specific cases, but this one is the most generic approach that yielded good results for me.
* Time is mostly orthogonal, since it can be used to move in any direction in the complexity/maturity space.

As always, if you have any feedback, don't hesitate to <a href="mailto:karl@karl.berlin">let me know</a>!
